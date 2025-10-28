# 🔧 Correction du Conflit de Politiques RLS

## ❌ Erreur Rencontrée

```
ERROR: 42710: policy "allow_all_userdatas" for table "UserDatas" already exists
```

Cette erreur signifie que les politiques RLS ont déjà été partiellement créées.

## ✅ Solution

Exécutez le script de correction qui nettoie et recrée tout proprement :

### Option 1 : Via Supabase Dashboard (Recommandé)

1. **Ouvrir le Dashboard Supabase**
2. **Aller dans "SQL Editor"**
3. **Copier le contenu de** `FIX_POLICIES_CONFLICT.sql`
4. **Coller dans l'éditeur**
5. **Cliquer sur "Run"** (ou Ctrl/Cmd + Enter)

### Option 2 : Via Supabase CLI

```bash
# Se placer dans le dossier du projet
cd /Users/gabriel/Dev/Perso/Web/hackathon-equipe-5

# Exécuter le script de correction
supabase db execute --file supabase/migrations/FIX_POLICIES_CONFLICT.sql
```

## 🎯 Ce que fait le script

1. ✅ **Supprime TOUTES les politiques existantes** (sans erreur si elles n'existent pas)
2. ✅ **Nettoie dynamiquement** toutes les politiques restantes
3. ✅ **Crée les fonctions RPC** (`increment_user_tokens`, `increment_team_tokens`)
4. ✅ **Recrée les politiques proprement** avec les bons noms
5. ✅ **Active RLS** sur les tables concernées
6. ✅ **Affiche un résumé** de ce qui a été créé

## ✅ Vérification

Après l'exécution, vous devriez voir :

```
✅ Fonctions RPC
  - increment_team_tokens
  - increment_user_tokens

✅ Politiques RLS
  - UserDatas → allow_all_userdatas
  - team_userdata → allow_all_team_userdata

✅ RLS Status
  - UserDatas → Activé
  - team_userdata → Activé

🎯 Le système de distribution des gains est maintenant opérationnel !
```

## 🧪 Test Rapide

Une fois le script exécuté, testez que tout fonctionne :

```sql
-- 1. Vérifier les fonctions
SELECT routine_name 
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE 'increment%';

-- 2. Vérifier les politiques
SELECT tablename, policyname
FROM pg_policies 
WHERE tablename IN ('UserDatas', 'team_userdata');

-- 3. Tester l'incrémentation (remplacez l'ID)
SELECT increment_user_tokens('VOTRE_USER_ID'::UUID, 10);
SELECT tokens FROM "UserDatas" WHERE id = 'VOTRE_USER_ID'::UUID;
```

## 🚀 Prochaines Étapes

Après avoir exécuté ce script :

1. ✅ Le système de distribution des gains devrait fonctionner
2. ✅ Vous pouvez définir des résultats et les gains seront distribués
3. ✅ Les paris passeront automatiquement en "terminé"

## 💡 Fichiers Importants

- `FIX_POLICIES_CONFLICT.sql` ← **Script de correction** (exécutez celui-ci)
- `20251028_SOLUTION_COMPLETE.sql` ← Migration originale (ne pas ré-exécuter)
- `test_distribution.sql` ← Script de test pour vérifier que tout fonctionne

## 🆘 Besoin d'Aide ?

Si le problème persiste après avoir exécuté le script :

1. **Vérifiez les logs** dans la console SQL de Supabase
2. **Copiez l'erreur complète** si vous en recevez une
3. **Consultez** `GUIDE_DISTRIBUTION_GAINS.md` pour plus de détails

### Solution Nucléaire (Développement Uniquement)

Si vraiment rien ne fonctionne, vous pouvez temporairement désactiver RLS :

```sql
-- ⚠️ DÉVELOPPEMENT UNIQUEMENT - Ne pas utiliser en production !
ALTER TABLE "UserDatas" DISABLE ROW LEVEL SECURITY;
ALTER TABLE team_userdata DISABLE ROW LEVEL SECURITY;
```

Cela permettra à la distribution de fonctionner sans restrictions.

---

**Note** : Ce script est sûr à exécuter plusieurs fois, il nettoie toujours avant de recréer.

