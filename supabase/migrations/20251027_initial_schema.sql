-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- UserDatas table
CREATE TABLE "UserDatas" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "auth_id" UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    "username" TEXT NOT NULL,
    "winrate" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "tokens" BIGINT NOT NULL DEFAULT 1000,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Teams table
CREATE TABLE "Teams" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "join_code" TEXT NOT NULL UNIQUE,
    "primary_color" TEXT NOT NULL DEFAULT '#3B82F6',
    "icon_url" TEXT NOT NULL DEFAULT '',
    "privacy" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Pronos table
CREATE TABLE "Pronos" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "team_id" UUID REFERENCES "Teams"("id") ON DELETE CASCADE,
    "event_id" TEXT,
    "owner_id" UUID NOT NULL REFERENCES "UserDatas"("id") ON DELETE CASCADE,
    "name" TEXT NOT NULL,
    "start_at" TIMESTAMPTZ NOT NULL,
    "end_at" TIMESTAMPTZ NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Bets table
CREATE TABLE "Bets" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "prono_id" UUID NOT NULL REFERENCES "Pronos"("id") ON DELETE CASCADE,
    "title" TEXT NOT NULL,
    "odds" DOUBLE PRECISION NOT NULL,
    "result" BOOLEAN,
    "option_id" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- team_userdata junction table
CREATE TABLE "team_userdata" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "joined_at" BIGINT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'member', 'banned', 'owner')),
    "userdata_id" UUID NOT NULL REFERENCES "UserDatas"("id") ON DELETE CASCADE,
    "team_id" UUID NOT NULL REFERENCES "Teams"("id") ON DELETE CASCADE,
    "token" BIGINT NOT NULL DEFAULT 1000,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE("userdata_id", "team_id")
);

-- bet_userdata junction table
CREATE TABLE "bet_userdata" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "amount" BIGINT NOT NULL,
    "created_at" BIGINT NOT NULL,
    "userdata_id" UUID NOT NULL REFERENCES "UserDatas"("id") ON DELETE CASCADE,
    "bet_id" UUID NOT NULL REFERENCES "Bets"("id") ON DELETE CASCADE,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_pronos_team_id ON "Pronos"("team_id");
CREATE INDEX idx_pronos_owner_id ON "Pronos"("owner_id");
CREATE INDEX idx_bets_prono_id ON "Bets"("prono_id");
CREATE INDEX idx_team_userdata_team_id ON "team_userdata"("team_id");
CREATE INDEX idx_team_userdata_userdata_id ON "team_userdata"("userdata_id");
CREATE INDEX idx_bet_userdata_bet_id ON "bet_userdata"("bet_id");
CREATE INDEX idx_bet_userdata_userdata_id ON "bet_userdata"("userdata_id");

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_userdatas_updated_at BEFORE UPDATE ON "UserDatas" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON "Teams" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pronos_updated_at BEFORE UPDATE ON "Pronos" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bets_updated_at BEFORE UPDATE ON "Bets" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_team_userdata_updated_at BEFORE UPDATE ON "team_userdata" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bet_userdata_updated_at BEFORE UPDATE ON "bet_userdata" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create UserData when a new user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public."UserDatas" (auth_id, username, winrate, tokens)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
        0.0,
        1000
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create UserData on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Row Level Security (RLS) Policies

-- Enable RLS
ALTER TABLE "UserDatas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Teams" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Pronos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Bets" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "team_userdata" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "bet_userdata" ENABLE ROW LEVEL SECURITY;

-- UserDatas policies
CREATE POLICY "Users can view all user data" ON "UserDatas" FOR SELECT USING (true);
CREATE POLICY "Users can update own data" ON "UserDatas" FOR UPDATE USING (auth.uid() = auth_id);

-- Teams policies
CREATE POLICY "Anyone can view public teams" ON "Teams" FOR SELECT USING (privacy = false OR EXISTS (
    SELECT 1 FROM "team_userdata" WHERE team_id = id AND userdata_id IN (
        SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
    )
));
CREATE POLICY "Members can view their private teams" ON "Teams" FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create teams" ON "Teams" FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Team owners can update teams" ON "Teams" FOR UPDATE USING (EXISTS (
    SELECT 1 FROM "team_userdata" WHERE team_id = id AND status = 'owner' AND userdata_id IN (
        SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
    )
));
CREATE POLICY "Team owners can delete teams" ON "Teams" FOR DELETE USING (EXISTS (
    SELECT 1 FROM "team_userdata" WHERE team_id = id AND status = 'owner' AND userdata_id IN (
        SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
    )
));

-- Pronos policies
CREATE POLICY "Anyone can view public pronos" ON "Pronos" FOR SELECT USING (team_id IS NULL OR EXISTS (
    SELECT 1 FROM "team_userdata" WHERE team_id = "Pronos".team_id AND userdata_id IN (
        SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
    ) AND status IN ('member', 'owner')
));
CREATE POLICY "Team owners can create pronos" ON "Pronos" FOR INSERT WITH CHECK (
    team_id IS NULL OR EXISTS (
        SELECT 1 FROM "team_userdata" WHERE team_id = "Pronos".team_id AND status = 'owner' AND userdata_id IN (
            SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
        )
    )
);
CREATE POLICY "Prono owners can update pronos" ON "Pronos" FOR UPDATE USING (owner_id IN (
    SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
));
CREATE POLICY "Prono owners can delete pronos" ON "Pronos" FOR DELETE USING (owner_id IN (
    SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
));

-- Bets policies
CREATE POLICY "Users can view bets if they can view the prono" ON "Bets" FOR SELECT USING (EXISTS (
    SELECT 1 FROM "Pronos" WHERE id = prono_id AND (team_id IS NULL OR EXISTS (
        SELECT 1 FROM "team_userdata" WHERE team_id = "Pronos".team_id AND userdata_id IN (
            SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
        ) AND status IN ('member', 'owner')
    ))
));
CREATE POLICY "Prono owners can create bets" ON "Bets" FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM "Pronos" WHERE id = prono_id AND owner_id IN (
        SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
    )
));
CREATE POLICY "Prono owners can update bets" ON "Bets" FOR UPDATE USING (EXISTS (
    SELECT 1 FROM "Pronos" WHERE id = prono_id AND owner_id IN (
        SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
    )
));
CREATE POLICY "Prono owners can delete bets" ON "Bets" FOR DELETE USING (EXISTS (
    SELECT 1 FROM "Pronos" WHERE id = prono_id AND owner_id IN (
        SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
    )
));

-- team_userdata policies
CREATE POLICY "Users can view team memberships for their teams" ON "team_userdata" FOR SELECT USING (
    userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()) OR
    team_id IN (SELECT team_id FROM "team_userdata" WHERE userdata_id IN (
        SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
    ))
);
CREATE POLICY "Users can join teams" ON "team_userdata" FOR INSERT WITH CHECK (
    userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);
CREATE POLICY "Team owners can update memberships" ON "team_userdata" FOR UPDATE USING (EXISTS (
    SELECT 1 FROM "team_userdata" tu WHERE tu.team_id = team_id AND tu.status = 'owner' AND tu.userdata_id IN (
        SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
    )
) OR userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()));
CREATE POLICY "Users can leave teams or owners can remove" ON "team_userdata" FOR DELETE USING (
    userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()) OR EXISTS (
        SELECT 1 FROM "team_userdata" tu WHERE tu.team_id = team_id AND tu.status = 'owner' AND tu.userdata_id IN (
            SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
        )
    )
);

-- bet_userdata policies
CREATE POLICY "Users can view their own bets" ON "bet_userdata" FOR SELECT USING (
    userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()) OR EXISTS (
        SELECT 1 FROM "Bets" b 
        JOIN "Pronos" p ON b.prono_id = p.id 
        WHERE b.id = bet_id AND p.owner_id IN (
            SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()
        )
    )
);
CREATE POLICY "Users can place bets" ON "bet_userdata" FOR INSERT WITH CHECK (
    userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);
CREATE POLICY "Users cannot update their bets once placed" ON "bet_userdata" FOR UPDATE USING (false);
CREATE POLICY "Users can delete their own bets before prono starts" ON "bet_userdata" FOR DELETE USING (
    userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid()) AND EXISTS (
        SELECT 1 FROM "Bets" b 
        JOIN "Pronos" p ON b.prono_id = p.id 
        WHERE b.id = bet_id AND p.start_at > NOW()
    )
);

