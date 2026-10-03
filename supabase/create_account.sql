-- ============================================================
-- إنشاء حساب من قاعدة البيانات فقط
-- التطبيق لا يوفّر صفحة «حساب جديد» — كل حساب يُصدر من هنا
-- أو من: Supabase Dashboard → Authentication → Users → Add user
-- ============================================================
-- شغّل هذا الملف مرة واحدة (بعد seed.sql)، ثم لإضافة أي مستخدم جديد
-- نفّذ سطر الاستدعاء في آخر الملف.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- دالة إنشاء حساب: البريد + كلمة المرور + الاسم + الصلاحية
-- الصلاحيات: 'admin' | 'music-editor' | 'listener'
CREATE OR REPLACE FUNCTION public.create_account(
    p_email TEXT,
    p_password TEXT,
    p_full_name TEXT DEFAULT NULL,
    p_role TEXT DEFAULT 'listener'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID;
BEGIN
    IF p_email IS NULL OR btrim(p_email) = '' THEN
        RAISE EXCEPTION 'البريد الإلكتروني مطلوب';
    END IF;

    IF p_password IS NULL OR length(p_password) < 6 THEN
        RAISE EXCEPTION 'كلمة المرور 6 أحرف على الأقل';
    END IF;

    IF p_role NOT IN ('admin', 'music-editor', 'listener') THEN
        RAISE EXCEPTION 'صلاحية غير معروفة: %', p_role;
    END IF;

    IF EXISTS (SELECT 1 FROM auth.users WHERE email = lower(btrim(p_email))) THEN
        RAISE EXCEPTION 'هذا البريد مسجّل مسبقًا: %', p_email;
    END IF;

    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change
    )
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        lower(btrim(p_email)),
        crypt(p_password, gen_salt('bf')),
        now(), -- تأكيد البريد مباشرة: لا حاجة لرسالة تفعيل
        '{"provider":"email","providers":["email"]}',
        jsonb_build_object('full_name', NULLIF(btrim(COALESCE(p_full_name, '')), '')),
        now(),
        now(),
        '',
        '',
        '',
        ''
    )
    RETURNING id INTO v_uid;

    -- الـ trigger on_auth_user_created ينشئ صف الـ profile تلقائيًا، نضبط الاسم والصلاحية
    UPDATE public.profiles
    SET full_name = NULLIF(btrim(COALESCE(p_full_name, '')), ''),
        role = p_role
    WHERE id = v_uid;

    RETURN v_uid;
END;
$$;

-- ============================================================
-- أمثلة — نفّذ السطر المطلوب فقط
-- ============================================================

-- كشاف عادي:
-- SELECT public.create_account('ahmed@example.com', 'password123', 'أحمد محمد');

-- محرر نوتات:
-- SELECT public.create_account('fares@example.com', 'password123', 'فارس السالم', 'music-editor');

-- قائد (صلاحية كاملة):
-- SELECT public.create_account('admin@example.com', 'password123', 'عمر الحارثي', 'admin');
