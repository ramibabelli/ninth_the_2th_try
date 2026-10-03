-- ============================================================
-- Music uploads: bucket + marker storage policies
-- الصق هذا الملف في قسم SQL Editor في Supabase (مرة واحدة فقط)
-- ============================================================

-- 1) إنشاء خزانة (bucket) عامة للمعزوفات
INSERT INTO storage.buckets (id, name, public)
VALUES ('music', 'music', true)
ON CONFLICT (id) DO NOTHING;

-- 2) رفع ملف صوتي: فقط music-editor / admin (عبر جدول profiles)
DROP POLICY IF EXISTS "Music editors upload tracks" ON storage.objects;
CREATE POLICY "Music editors upload tracks" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'music'
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role IN ('music-editor', 'admin')
        )
    );

-- 3) تعديل/استبدال ملف: للمحررين فقط
DROP POLICY IF EXISTS "Music editors update tracks" ON storage.objects;
CREATE POLICY "Music editors update tracks" ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'music'
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role IN ('music-editor', 'admin')
        )
    );

-- 4) حذف ملف: للمحررين فقط
DROP POLICY IF EXISTS "Music editors delete tracks" ON storage.objects;
CREATE POLICY "Music editors delete tracks" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'music'
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role IN ('music-editor', 'admin')
        )
    );

-- 5) قراءة/تشغيل الملفات: متاحة للجميع (الخزانة عامة)
DROP POLICY IF EXISTS "Public read music objects" ON storage.objects;
CREATE POLICY "Public read music objects" ON storage.objects
    FOR SELECT USING (bucket_id = 'music');