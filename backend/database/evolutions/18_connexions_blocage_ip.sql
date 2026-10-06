-- Blocage temporaire des connexions après plusieurs échecs depuis une même adresse IP :
-- les derniers échecs d'une adresse sont relus à chaque tentative de connexion.

CREATE INDEX IF NOT EXISTS idx_connexions_ip
    ON public.connexions (ip_adresse, created_at DESC);
