-- Migration pour permettre la distribution automatique des gains
-- Date: 28 Octobre 2025
-- Objectif: Permettre aux fonctions serveur de mettre à jour les tokens

-- ==================================================================
-- OPTION 1: Ajouter des politiques UPDATE pour la distribution
-- ==================================================================

-- Politique pour permettre aux utilisateurs de recevoir des gains (UserDatas)
DROP POLICY IF EXISTS "allow_token_distribution_public" ON "UserDatas";
CREATE POLICY "allow_token_distribution_public"
ON "UserDatas"
FOR UPDATE
USING (true)  -- Permet toute mise à jour (simplifié pour le hackathon)
WITH CHECK (true);

-- Politique pour permettre la mise à jour des tokens de groupe
DROP POLICY IF EXISTS "allow_token_distribution_group" ON team_userdata;
CREATE POLICY "allow_token_distribution_group"
ON team_userdata
FOR UPDATE
USING (true)  -- Permet toute mise à jour (simplifié pour le hackathon)
WITH CHECK (true);

-- ==================================================================
-- VÉRIFICATION: Si ça ne fonctionne toujours pas, utiliser cette option
-- ==================================================================

-- Alternative: Désactiver temporairement RLS (UNIQUEMENT POUR LE DÉVELOPPEMENT)
-- Décommentez ces lignes si nécessaire :

-- ALTER TABLE "UserDatas" DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE team_userdata DISABLE ROW LEVEL SECURITY;

-- Pour réactiver après les tests:
-- ALTER TABLE "UserDatas" ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE team_userdata ENABLE ROW LEVEL SECURITY;

-- ==================================================================
-- Vérifier les politiques existantes
-- ==================================================================

-- Pour voir toutes les politiques sur UserDatas:
-- SELECT * FROM pg_policies WHERE tablename = 'UserDatas';

-- Pour voir toutes les politiques sur team_userdata:
-- SELECT * FROM pg_policies WHERE tablename = 'team_userdata';


