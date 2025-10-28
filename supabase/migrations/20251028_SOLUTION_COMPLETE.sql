-- ============================================================================
-- SOLUTION COMPLÈTE - Distribution des Gains
-- ============================================================================
-- Ce script crée des fonctions PostgreSQL pour incrémenter les tokens
-- et configure les RLS pour permettre ces opérations
-- ============================================================================

-- ===========================================================================
-- 1. Créer les fonctions d'incrémentation de tokens
-- ===========================================================================

-- Fonction pour incrémenter les tokens publics d'un utilisateur
CREATE OR REPLACE FUNCTION increment_user_tokens(
  user_id UUID,
  amount_to_add BIGINT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- Exécute avec les privilèges du propriétaire de la fonction
AS $$
BEGIN
  UPDATE "UserDatas"
  SET tokens = tokens + amount_to_add
  WHERE id = user_id;
END;
$$;

-- Fonction pour incrémenter les tokens de groupe
CREATE OR REPLACE FUNCTION increment_team_tokens(
  p_team_id UUID,
  p_user_id UUID,
  amount_to_add BIGINT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- Exécute avec les privilèges du propriétaire de la fonction
AS $$
BEGIN
  UPDATE team_userdata
  SET token = token + amount_to_add
  WHERE team_id = p_team_id AND userdata_id = p_user_id;
END;
$$;

-- ===========================================================================
-- 2. Supprimer toutes les politiques RLS existantes sur UserDatas
-- ===========================================================================

DROP POLICY IF EXISTS "allow_token_distribution_public" ON "UserDatas";
DROP POLICY IF EXISTS "view_all_users" ON "UserDatas";
DROP POLICY IF EXISTS "update_own_profile" ON "UserDatas";
DROP POLICY IF EXISTS "allow_all_operations_userdatas" ON "UserDatas";
DROP POLICY IF EXISTS "select_own_data" ON "UserDatas";
DROP POLICY IF EXISTS "insert_own_data" ON "UserDatas";
DROP POLICY IF EXISTS "update_own_data" ON "UserDatas";

-- ===========================================================================
-- 3. Supprimer toutes les politiques RLS existantes sur team_userdata
-- ===========================================================================

DROP POLICY IF EXISTS "allow_token_distribution_group" ON team_userdata;
DROP POLICY IF EXISTS "select_own_memberships" ON team_userdata;
DROP POLICY IF EXISTS "insert_membership" ON team_userdata;
DROP POLICY IF EXISTS "update_membership" ON team_userdata;
DROP POLICY IF EXISTS "allow_all_operations_team_userdata" ON team_userdata;
DROP POLICY IF EXISTS "select_team_memberships" ON team_userdata;
DROP POLICY IF EXISTS "insert_team_membership" ON team_userdata;
DROP POLICY IF EXISTS "update_team_membership" ON team_userdata;

-- ===========================================================================
-- 4. Créer UNE SEULE politique permissive pour chaque table
-- ===========================================================================

-- Politique permissive totale pour UserDatas (pour le hackathon)
CREATE POLICY "allow_all_userdatas"
ON "UserDatas"
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Politique permissive totale pour team_userdata (pour le hackathon)
CREATE POLICY "allow_all_team_userdata"
ON team_userdata
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- ===========================================================================
-- 5. S'assurer que RLS est activé
-- ===========================================================================

ALTER TABLE "UserDatas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_userdata ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- 6. TEST - Vérifier que tout fonctionne
-- ===========================================================================

-- Voir les politiques créées
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename IN ('UserDatas', 'team_userdata')
ORDER BY tablename, policyname;

-- Tester les fonctions (décommentez et adaptez les IDs pour tester)
-- SELECT increment_user_tokens('votre-user-id'::UUID, 100);
-- SELECT * FROM "UserDatas" WHERE id = 'votre-user-id'::UUID;

-- ===========================================================================
-- 7. CONFIRMATION
-- ===========================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Fonctions créées : increment_user_tokens et increment_team_tokens';
  RAISE NOTICE '✅ Politiques RLS simplifiées et permissives créées';
  RAISE NOTICE '✅ RLS activé sur UserDatas et team_userdata';
  RAISE NOTICE '🎯 La distribution des gains devrait maintenant fonctionner !';
END $$;


