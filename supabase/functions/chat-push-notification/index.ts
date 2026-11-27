import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

// Interfaz del payload enviado por el Webhook de Supabase al insertar un mensaje
interface WebhookPayload {
  type: "INSERT";
  table: "chat_messages";
  record: {
    id: string;
    conversation_id: string;
    sender_id: string;
    text: string;
    created_at: string;
  };
  schema: string;
}

// Genera un token OAuth2 de Google a partir de la cuenta de servicio de Firebase
async function getAccessToken(serviceAccount: any): Promise<string> {
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;

  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp,
    iat,
  };

  const encodeBase64Url = (input: string) => {
    return btoa(input)
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");
  };

  const strHeader = encodeBase64Url(JSON.stringify(header));
  const strClaim = encodeBase64Url(JSON.stringify(claim));
  const signInput = `${strHeader}.${strClaim}`;

  // Importar clave privada RSA
  const pem = serviceAccount.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const binaryDer = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signInput)
  );

  const strSignature = encodeBase64Url(
    String.fromCharCode(...new Uint8Array(signature))
  );

  const jwt = `${signInput}.${strSignature}`;

  // Intercambiar JWT por Access Token de Google
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token;
}

serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json();
    const record = payload.record;

    if (!record || !record.conversation_id || !record.sender_id) {
      return new Response(JSON.stringify({ error: "Payload inválido" }), { status: 400 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const firebaseServiceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!;

    if (!firebaseServiceAccountJson) {
      return new Response(
        JSON.stringify({ error: "Variable FIREBASE_SERVICE_ACCOUNT no configurada" }),
        { status: 500 }
      );
    }

    const firebaseServiceAccount = JSON.parse(firebaseServiceAccountJson);
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Obtener la conversación para saber quién es el destinatario
    const { data: conv, error: convError } = await supabase
      .from("chat_conversations")
      .select("owner_id, renter_id, apartment_title")
      .eq("id", record.conversation_id)
      .single();

    if (convError || !conv) {
      return new Response(JSON.stringify({ error: "Conversación no encontrada" }), { status: 404 });
    }

    // El destinatario es el otro participante
    const recipientId = record.sender_id === conv.owner_id ? conv.renter_id : conv.owner_id;

    // 2. Obtener el nombre del remitente
    const { data: sender } = await supabase
      .from("profiles")
      .select("name")
      .eq("id", record.sender_id)
      .single();

    const senderName = sender?.name || "Nuevo mensaje";

    // 3. Obtener el token FCM del destinatario
    const { data: recipient, error: recipientError } = await supabase
      .from("profiles")
      .select("fcm_token")
      .eq("id", recipientId)
      .single();

    if (recipientError || !recipient || !recipient.fcm_token) {
      return new Response(
        JSON.stringify({ message: "El destinatario no tiene fcm_token registrado aún" }),
        { status: 200 }
      );
    }

    // 4. Obtener OAuth token y enviar notificación push a FCM HTTP v1
    const accessToken = await getAccessToken(firebaseServiceAccount);
    const projectId = firebaseServiceAccount.project_id;

    const fcmPayload = {
      message: {
        token: recipient.fcm_token,
        notification: {
          title: `Mensaje de ${senderName}`,
          body: record.text,
        },
        data: {
          conversation_id: record.conversation_id,
          apartment_title: conv.apartment_title || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channel_id: "forade_chat_channel",
            priority: "max",
          },
        },
      },
    };

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(fcmPayload),
      }
    );

    const fcmData = await fcmRes.json();

    return new Response(JSON.stringify({ success: true, fcmData }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
