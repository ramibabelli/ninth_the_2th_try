-- ============================================================
-- Ninth Scout — قاعدة بيانات مصححة كاملة
-- تُلصق مرة واحدة في SQL Editor (قسم Database في Supabase)
-- ============================================================

-- تنظيف الجداول السابقة إن وجدت
DROP TABLE IF EXISTS public.posts CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.music_tracks CASCADE;

-- دوال UUID متاحة أصلاً في Supabase (pgcrypto)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. جدول الحسابات (مرتبط بـ auth.users عبر id فقط)
--    ملاحظة: id هو نفس id المستخدم في قسم Authentication.
--    لا نكرر اسم المستخدم/البريد هنا — تبقى في auth.users.
-- ============================================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    role TEXT DEFAULT 'listener',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ============================================================
-- 2. جدول البوستات
-- ============================================================
CREATE TABLE public.posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    video_url TEXT, -- [تعديل] دعم فيديو المنشورات: رابط الفيديو في نفس خزانة posts
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ============================================================
-- 3. جدول المعرض / المنتجات
-- ============================================================
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ============================================================
-- 4. جدول الموسيقى / المعزوفات والنوتات
-- ============================================================
CREATE TABLE public.music_tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    notes TEXT, -- النوتات الحرفية مثل (دو - ري - مي)
    audio_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ============================================================
-- تفعيل حماية Row Level Security
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.music_tracks ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- الصلاحيات (GRANT) الأساسية.
-- بدونها تبقى كل الاستعلامات مرفوضة مهما كانت القواعد سليمة،
-- وهذا غالبًا سبب «حدث خطأ غير متوقع».
-- ============================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon, authenticated;

-- ============================================================
-- Trigger: ينشئ تلقائيًا صف الحساب (profile) مع كل مستخدم جديد،
-- حتى الذي يُنشأ من تبويب Authentication مباشرة.
-- الذي كان يُنشأ خارج التطبيق كان يبقى بدون صف → أصبح يظهر باسم «كشاف».
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- يمتلك صلاحية تجاوز RLS أثناء الإنشاء فقط
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name')
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- إعادة تعبئة الحسابات الموجودة سلفًا التي لا تملك صفًا
INSERT INTO public.profiles (id, full_name)
SELECT u.id, COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name')
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);

-- ============================================================
-- سياسات RLS
-- ============================================================

-- Profiles
DROP POLICY IF EXISTS "Profiles viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles viewable by everyone" ON public.profiles
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert/update own profile" ON public.profiles;
CREATE POLICY "Users can insert/update own profile" ON public.profiles
    FOR ALL USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id); -- ضروري لإدراج صف الفرد نفسها

-- Role-based access: users can update their own role
DROP POLICY IF EXISTS "Users can update own role" ON public.profiles;
CREATE POLICY "Users can update own role" ON public.profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Posts (مشاهدة للجميع، نشر فقط لصاحب الصف نفسه)
DROP POLICY IF EXISTS "Posts viewable by everyone" ON public.posts;
CREATE POLICY "Posts viewable by everyone" ON public.posts
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create posts" ON public.posts;
CREATE POLICY "Authenticated users can create posts" ON public.posts
    FOR INSERT WITH CHECK (auth.uid() = author_id); -- يمنع سبوفينغ author_id

-- [تعديل] أزرار التعديل/الحذف على منشورات صاحب الحساب فقط
DROP POLICY IF EXISTS "Post owners can update" ON public.posts;
CREATE POLICY "Post owners can update" ON public.posts
    FOR UPDATE USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Post owners can delete" ON public.posts;
CREATE POLICY "Post owners can delete" ON public.posts
    FOR DELETE USING (auth.uid() = author_id);

-- Products & Music (عرض للجميع)
DROP POLICY IF EXISTS "Products viewable by everyone" ON public.products;
CREATE POLICY "Products viewable by everyone" ON public.products
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Music viewable by everyone" ON public.music_tracks;
CREATE POLICY "Music viewable by everyone" ON public.music_tracks
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Music editors can manage" ON public.music_tracks;
CREATE POLICY "Music editors can manage" ON public.music_tracks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role IN ('music-editor', 'admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role IN ('music-editor', 'admin')
        )
    );

-- ============================================================
-- Storage: إنشاء الخزنات وقواعدها
-- يُنفذ هذا القسم بعد إنشاء الخزنات البكرة في قسم Storage.
-- إن كانت الخزنات منشأة سلفًا، الأحكام التالية تعمل عليها مباشرة.
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('posts', 'posts', true),
       ('avatars', 'avatars', true),
       ('products', 'products', true)
ON CONFLICT (id) DO NOTHING;

-- رفع: أي مستخدم مسجل يرفع إلى مجلد عمله
DROP POLICY IF EXISTS "Store own files" ON storage.objects;
CREATE POLICY "Store own files" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id IN ('posts', 'avatars', 'products')
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- تعديل/حذف ملفات العمله
DROP POLICY IF EXISTS "Manage own files" ON storage.objects;
CREATE POLICY "Manage own files" ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id IN ('posts', 'avatars', 'products')
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
CREATE POLICY "Delete own files" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id IN ('posts', 'avatars', 'products')
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- مشاهدة: الخزنات عامة
DROP POLICY IF EXISTS "Public read objects" ON storage.objects;
CREATE POLICY "Public read objects" ON storage.objects
    FOR SELECT USING (bucket_id IN ('posts', 'avatars', 'products'));