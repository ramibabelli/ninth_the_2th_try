-- ============================================================
-- Ninth Scout — إضافة دعم الفيديو + أزرار تعديل/حذف المنشورات
-- ملف الترقية لقاعدة بيانات موجودة بالفعل.
-- [الذي سيتم تعديله عليك]
-- ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
-- ▓▓ نقطة التعديل في قاعدة بياناتك الحالية:                     ▓▓
-- ▓▓ 1) سنجعل هذا الملف كاملاً في SQL Editor (قسم Database).   ▓▓
-- ▓▓ 2) سيضيف عمود video_url إن لم يكن موجوداً.               ▓▓
-- ▓▓ 3) سيضيف قواعد التحديث والحذف على posts.                 ▓▓
-- ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
-- ملاحظة: إن طبّقت ملف seed.sql من جديد فلا حاجة لهذا الملف،
-- لأن seed.sql يحتوي هذه التعديلات أصلاً.
-- ============================================================

-- [معدّل] عمود الفيديو على جدول المنشورات
ALTER TABLE public.posts
    ADD COLUMN IF NOT EXISTS video_url TEXT;

-- [معدّل] قاعدة التعديل: صاحب الحساب فقط يعدّل منشوره
DROP POLICY IF EXISTS "Post owners can update" ON public.posts;
CREATE POLICY "Post owners can update" ON public.posts
    FOR UPDATE USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);

-- [معدّل] قاعدة الحذف: صاحب الحساب فقط يحذف منشوره
DROP POLICY IF EXISTS "Post owners can delete" ON public.posts;
CREATE POLICY "Post owners can delete" ON public.posts
    FOR DELETE USING (auth.uid() = author_id);