-- ============================================================================
-- FIX - Permissions RLS pour la Création de Pronos
-- ============================================================================
-- Ce script corrige les permissions pour permettre la création de pronos
-- pour les groupes et les paris publics
-- ============================================================================

-- ===========================================================================
-- 1. SUPPRIMER LES ANCIENNES POLITIQUES SUR PRONOS
-- ===========================================================================

DROP POLICY IF EXISTS "allow_insert_pronos" ON "Pronos";
DROP POLICY IF EXISTS "allow_select_pronos" ON "Pronos";
DROP POLICY IF EXISTS "allow_update_pronos" ON "Pronos";
DROP POLICY IF EXISTS "allow_delete_pronos" ON "Pronos";
DROP POLICY IF EXISTS "allow_all_pronos" ON "Pronos";

-- ===========================================================================
-- 2. CRÉER DES POLITIQUES PERMISSIVES POUR PRONOS
-- ===========================================================================

-- Tout le monde peut voir les pronos
CREATE POLICY "allow_select_pronos"
ON "Pronos"
FOR SELECT
TO authenticated
USING (true);

-- Les utilisateurs authentifiés peuvent créer des pronos
CREATE POLICY "allow_insert_pronos"
ON "Pronos"
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() IS NOT NULL);

-- Les propriétaires peuvent mettre à jour leurs pronos
CREATE POLICY "allow_update_own_pronos"
ON "Pronos"
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM "UserDatas"
    WHERE "UserDatas".id = "Pronos".owner_id
    AND "UserDatas".auth_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM "UserDatas"
    WHERE "UserDatas".id = "Pronos".owner_id
    AND "UserDatas".auth_id = auth.uid()
  )
);

-- Les propriétaires peuvent supprimer leurs pronos
CREATE POLICY "allow_delete_own_pronos"
ON "Pronos"
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM "UserDatas"
    WHERE "UserDatas".id = "Pronos".owner_id
    AND "UserDatas".auth_id = auth.uid()
  )
);

-- ===========================================================================
-- 3. SUPPRIMER LES ANCIENNES POLITIQUES SUR BETS
-- ===========================================================================

DROP POLICY IF EXISTS "allow_insert_bets" ON "Bets";
DROP POLICY IF EXISTS "allow_select_bets" ON "Bets";
DROP POLICY IF EXISTS "allow_update_bets" ON "Bets";
DROP POLICY IF EXISTS "allow_delete_bets" ON "Bets";
DROP POLICY IF EXISTS "allow_all_bets" ON "Bets";

-- ===========================================================================
-- 4. CRÉER DES POLITIQUES PERMISSIVES POUR BETS
-- ===========================================================================

-- Tout le monde peut voir les bets
CREATE POLICY "allow_select_bets"
ON "Bets"
FOR SELECT
TO authenticated
USING (true);

-- Les propriétaires de pronos peuvent créer des bets
CREATE POLICY "allow_insert_bets"
ON "Bets"
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM "Pronos" p
    INNER JOIN "UserDatas" u ON u.id = p.owner_id
    WHERE p.id = "Bets".prono_id
    AND u.auth_id = auth.uid()
  )
);

-- Les propriétaires de pronos peuvent mettre à jour les bets (résultats)
CREATE POLICY "allow_update_bets"
ON "Bets"
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM "Pronos" p
    INNER JOIN "UserDatas" u ON u.id = p.owner_id
    WHERE p.id = "Bets".prono_id
    AND u.auth_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM "Pronos" p
    INNER JOIN "UserDatas" u ON u.id = p.owner_id
    WHERE p.id = "Bets".prono_id
    AND u.auth_id = auth.uid()
  )
);

-- Les propriétaires de pronos peuvent supprimer les bets
CREATE POLICY "allow_delete_bets"
ON "Bets"
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM "Pronos" p
    INNER JOIN "UserDatas" u ON u.id = p.owner_id
    WHERE p.id = "Bets".prono_id
    AND u.auth_id = auth.uid()
  )
);

-- ===========================================================================
-- 5. ACTIVER RLS SUR LES TABLES
-- ===========================================================================

ALTER TABLE "Pronos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Bets" ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- 6. VÉRIFICATION
-- ===========================================================================

-- Afficher les politiques créées pour Pronos
SELECT 
  '✅ Politiques Pronos' as "Status",
  policyname as "Politique",
  cmd as "Commande"
FROM pg_policies 
WHERE tablename = 'Pronos'
ORDER BY policyname;

-- Afficher les politiques créées pour Bets
SELECT 
  '✅ Politiques Bets' as "Status",
  policyname as "Politique",
  cmd as "Commande"
FROM pg_policies 
WHERE tablename = 'Bets'
ORDER BY policyname;

-- ===========================================================================
-- 7. CONFIRMATION
-- ===========================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
  RAISE NOTICE '║  ✅ PERMISSIONS RLS POUR PRONOS CONFIGURÉES              ║';
  RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Les utilisateurs peuvent maintenant :';
  RAISE NOTICE '   - Créer des pronos (publics ou de groupe)';
  RAISE NOTICE '   - Voir tous les pronos';
  RAISE NOTICE '   - Modifier/Supprimer leurs propres pronos';
  RAISE NOTICE '   - Créer des options de pari pour leurs pronos';
  RAISE NOTICE '   - Définir les résultats de leurs pronos';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Vous pouvez maintenant créer des pronos pour vos groupes !';
  RAISE NOTICE '';
END $$;

