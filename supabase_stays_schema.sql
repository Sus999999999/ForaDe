-- ============================================================
-- TABLA: stays (historial de rentas)
-- Ejecuta este script en el SQL Editor de Supabase
-- ============================================================

CREATE TABLE IF NOT EXISTS public.stays (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  renter_id            UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  owner_id             UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  apartment_id         UUID        NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  apartment_title      TEXT        NOT NULL,
  location             TEXT        NOT NULL DEFAULT '',
  host_name            TEXT        NOT NULL DEFAULT '',
  monthly_price_cents  INTEGER     NOT NULL,
  renter_name          TEXT        NOT NULL DEFAULT '',
  start_date           TIMESTAMPTZ NOT NULL DEFAULT now(),
  end_date             TIMESTAMPTZ,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE public.stays ENABLE ROW LEVEL SECURITY;

-- El dueño y el rentador pueden ver sus propias rentas
CREATE POLICY "Ver propias rentas"
  ON public.stays FOR SELECT TO authenticated
  USING (auth.uid() = renter_id OR auth.uid() = owner_id);

-- Solo el dueño puede insertar (aceptar renta)
CREATE POLICY "Owner puede aceptar renta"
  ON public.stays FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = owner_id);

-- Dueño o rentador pueden actualizar (cancelar/finalizar renta → poner end_date)
CREATE POLICY "Participantes pueden actualizar renta"
  ON public.stays FOR UPDATE TO authenticated
  USING (auth.uid() = owner_id OR auth.uid() = renter_id);

-- Índices
CREATE INDEX IF NOT EXISTS idx_stays_renter    ON public.stays(renter_id);
CREATE INDEX IF NOT EXISTS idx_stays_owner     ON public.stays(owner_id);
CREATE INDEX IF NOT EXISTS idx_stays_apartment ON public.stays(apartment_id);
