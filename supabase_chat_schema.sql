-- ==============================================================================
-- FORADE: Script DDL para Mensajería en Tiempo Real y Notificaciones (Fase 5)
-- ==============================================================================
-- Ejecuta este script en el SQL Editor de tu panel de Supabase.
-- Habilita las tablas 'chat_conversations' y 'chat_messages',
-- configura las políticas de seguridad (RLS) y la publicación de Supabase Realtime (WebSockets).

-- 1. Tabla de Conversaciones de Chat
CREATE TABLE IF NOT EXISTS public.chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
    apartment_title TEXT NOT NULL,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    renter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Evitar duplicar una conversación sobre el mismo departamento entre el mismo rentador y rentero
    CONSTRAINT unique_apartment_renter UNIQUE (apartment_id, renter_id)
);

-- 2. Tabla de Mensajes
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.chat_conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Índices para acelerar búsquedas y filtros en tiempo real
CREATE INDEX IF NOT EXISTS idx_chat_conversations_owner ON public.chat_conversations(owner_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_renter ON public.chat_conversations(renter_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_apt ON public.chat_conversations(apartment_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conv_created ON public.chat_messages(conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender ON public.chat_messages(sender_id);

-- 4. Habilitar Row Level Security (RLS)
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- 5. Políticas de Seguridad (RLS) para 'chat_conversations'
DROP POLICY IF EXISTS "Los participantes pueden ver sus conversaciones" ON public.chat_conversations;
CREATE POLICY "Los participantes pueden ver sus conversaciones"
ON public.chat_conversations FOR SELECT
USING (auth.uid() = owner_id OR auth.uid() = renter_id);

DROP POLICY IF EXISTS "Los usuarios autenticados pueden crear conversaciones" ON public.chat_conversations;
CREATE POLICY "Los usuarios autenticados pueden crear conversaciones"
ON public.chat_conversations FOR INSERT
WITH CHECK (auth.uid() = renter_id OR auth.uid() = owner_id);

DROP POLICY IF EXISTS "Los participantes pueden actualizar sus conversaciones" ON public.chat_conversations;
CREATE POLICY "Los participantes pueden actualizar sus conversaciones"
ON public.chat_conversations FOR UPDATE
USING (auth.uid() = owner_id OR auth.uid() = renter_id);

DROP POLICY IF EXISTS "Los participantes pueden eliminar sus conversaciones" ON public.chat_conversations;
CREATE POLICY "Los participantes pueden eliminar sus conversaciones"
ON public.chat_conversations FOR DELETE
USING (auth.uid() = owner_id OR auth.uid() = renter_id);

-- 6. Políticas de Seguridad (RLS) para 'chat_messages'
DROP POLICY IF EXISTS "Los participantes de la conversación pueden ver los mensajes" ON public.chat_messages;
CREATE POLICY "Los participantes de la conversación pueden ver los mensajes"
ON public.chat_messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.chat_conversations c
        WHERE c.id = chat_messages.conversation_id
        AND (c.owner_id = auth.uid() OR c.renter_id = auth.uid())
    )
);

DROP POLICY IF EXISTS "Los participantes pueden enviar mensajes" ON public.chat_messages;
CREATE POLICY "Los participantes pueden enviar mensajes"
ON public.chat_messages FOR INSERT
WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
        SELECT 1 FROM public.chat_conversations c
        WHERE c.id = chat_messages.conversation_id
        AND (c.owner_id = auth.uid() OR c.renter_id = auth.uid())
    )
);

DROP POLICY IF EXISTS "Los participantes pueden borrar mensajes si la conversación se elimina" ON public.chat_messages;
CREATE POLICY "Los participantes pueden borrar mensajes si la conversación se elimina"
ON public.chat_messages FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.chat_conversations c
        WHERE c.id = chat_messages.conversation_id
        AND (c.owner_id = auth.uid() OR c.renter_id = auth.uid())
    )
);

-- 7. Trigger para actualizar automáticamente 'updated_at' en la conversación al enviar un nuevo mensaje
CREATE OR REPLACE FUNCTION public.handle_new_chat_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.chat_conversations
    SET updated_at = NEW.created_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_chat_message_inserted ON public.chat_messages;
CREATE TRIGGER on_chat_message_inserted
AFTER INSERT ON public.chat_messages
FOR EACH ROW EXECUTE FUNCTION public.handle_new_chat_message();

-- 8. Habilitar Supabase Realtime (WebSockets) para transmisión en vivo
-- Nota: La publicación 'supabase_realtime' ya existe por defecto en Supabase.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'chat_conversations'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_conversations;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'chat_messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
    END IF;
END $$;

-- 9. Columna para token de Notificaciones Push (FCM) en 'profiles'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'fcm_token'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN fcm_token TEXT DEFAULT '';
    END IF;
END $$;
