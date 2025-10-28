export const useShop = () => {
    const supabase = useSupabaseClient()
    const { whenUserDataReady } = useUserData()

    const ensureUser = async () => {
        const ud = await whenUserDataReady()
        if (!ud) throw new Error('User not authenticated')
        return ud
    }

    const getItems = async () => {
        return [
            {
                "id": "0a1b2c3d-0001-4f2a-9cde-111111111111",
                "name": "Badge VIP",
                "description": "Badge profil exclusif affiché à côté de votre pseudo.",
                "price": 150,
                "category": "privileges",
                "image": "https://cdn.discordapp.com/attachments/1290702630594805902/1432876426914431056/CleanShot_2025-10-29_at_00.39.132x.png?ex=6902a5a9&is=69015429&hm=3abb49565cc9f4c49da39c2203074854ae4ba24897852375026404af93669784&",
                "limited": false,
                "created_at": "2025-09-10T10:12:00Z"
            },
            {
                "id": "0a1b2c3d-0002-4f2a-9cde-222222222222",
                "name": "Reconnaissance éternelle",
                "description": "Vous recevrez une reconnaissance éternelle de la part de l'équipe pour vos gains.",
                "price": 50,
                "category": "cosmetics",
                "image": "https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExdGU5djJ3ODN5NmsyNmx3N3QyYXc4cjZyaHBtMnNjdHlpbHgxbnFlcyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/dxbgh0IRC6UDu/giphy.gif",
                "limited": false,
                "created_at": "2025-08-21T09:00:00Z"
            },
            {
                "id": "0a1b2c3d-000d-4f2a-9cde-dddddddddddd",
                "name": "Box Mystère du Supporter",
                "description": "Reçois un goodie surprise (virtuel) : badge, boost ou privilège aléatoire. Pari sur ton pari.",
                "price": 2000,
                "category": "privileges",
                "image": "https://lavage-nettoyage-auto.fr/wp-content/uploads/2021/04/BOITE-MYSTERE-MYSTERY-BOX-SuRpRiSe-Geek-Jeux-video.jpg",
                "limited": false,
                "created_at": "2025-09-15T14:30:00Z"
            },
            {
                "id": "0a1b2c3d-0004-4f2a-9cde-444444444444",
                "name": "Couleur de pseudo",
                "description": "Change la couleur de ton pseudo dans les classements.",
                "price": 20000,
                "category": "cosmetics",
                "image": "https://cdn.discordapp.com/attachments/1290702630594805902/1432875534991229113/CleanShot_2025-10-29_at_00.35.382x.png?ex=6902a4d5&is=69015355&hm=f50a9379c56e7a33b0339c84800be79555064568a1975f469c435aaac5c9b8aa&",
                "limited": false,
                "created_at": "2025-07-15T12:00:00Z"
            },
            {
                "id": "0a1b2c3d-0006-4f2a-9cde-666666666666",
                "name": "Après-midi avec l'équipe",
                "description": "Passe une après-midi avec l'équipe de développement pour discuter de vos paris et de vos gains !",
                "price": 500000,
                "category": "privileges",
                "image": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExc2ZsNHVqcWYzMndkb2Z2c3dyZHF0bWUwanh4MmVraTQxdTR0ajYyMCZlcD12MV9naWZzX3NlYXJjaCZjdD1n/8VekdtUYdBWWmPzChj/giphy.gif",
                "limited": true,
                "created_at": "2025-10-05T18:20:00Z"
            },
            {
                "id": "0a1b2c3d-0007-4f2a-9cde-777777777777",
                "name": "Boost Publicités",
                "description": "Double la récompense tokens des 5 prochaines publicités que tu regardes !",
                "price": 200,
                "category": "boosts",
                "image": "data:image/jpeg;base64,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",
                "limited": false,
                "created_at": "2025-06-02T11:11:00Z"
            },
            {
                "id": "0a1b2c3d-0008-4f2a-9cde-888888888888",
                "name": "Avatar animé",
                "description": "Avatar animé pour ton profil (GIF loop).",
                "price": 400,
                "category": "cosmetics",
                "image": "https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExaXV2a2ViYXNtMDVtejlkc2NyOHRoNmNiYnNlcTczY2lnbzkyZHl0cCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/ASd0Ukj0y3qMM/giphy.gif",
                "limited": false,
                "created_at": "2025-09-01T07:30:00Z"
            }
        ]
    }

    const purchaseItem = async (itemId: string) => {
        const item = (await getItems()).find(i => i.id === itemId)

        if (!item) {
            throw new Error('Item not found')
        }

        const userData = await ensureUser()
        if (userData.tokens < item.price) {
            throw new Error('Insufficient tokens')
        }

        const { deductTokens } = useTokens()

        const success = await deductTokens(item.price)

        if (!success) {
            throw new Error('Failed to deduct tokens')
        }
    }

    return {
        getItems,
        purchaseItem,
    }
}

export interface ShopItem {
    id: string
    name: string
    description?: string
    price: number
    category: 'cosmetics' | 'boosts' | 'privileges'
    image?: string
    limited?: boolean
    created_at?: string | number
}