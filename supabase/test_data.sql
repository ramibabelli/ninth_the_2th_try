-- Test data for multi-role RBAC system
-- Run this after applying seed.sql

-- Sample profiles with different roles
-- Music Editor user (user-id: music-editor-test-id)
INSERT INTO public.profiles (id, full_name, role)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'فارس السالم',
    'music-editor'
);

-- Admin user
INSERT INTO public.profiles (id, full_name, role)
VALUES (
    '00000000-0000-0000-0000-000000000002',
    'عمر الحارثي',
    'admin'
);

-- Regular listener user (default role)
INSERT INTO public.profiles (id, full_name, role)
VALUES (
    '00000000-0000-0000-0000-000000000003',
    'محمد عبدالله',
    'listener'
);

-- Another listener without explicit role (will get default 'listener')
INSERT INTO public.profiles (id, full_name)
VALUES (
    '00000000-0000-0000-0000-000000000004',
    'اسماعيل محمد'
);

-- Sample music tracks
-- Track added by music-editor
INSERT INTO public.music_tracks (title, description, notes, audio_url, created_at)
VALUES (
    'أنشودة الصباح',
    'أنشودة ترحيبية للناشئة',
    'دو - ري - Mi - Fa',
    'https://example.com/audio/morning-song.mp3',
    timezone('utc'::text, now())
);

-- Track added by admin
INSERT INTO public.music_tracks (title, description, notes, audio_url, created_at)
VALUES (
    'قطف الثمار',
    'وصف للعمل الفلاحي',
    'لا - سي - دو',
    'https://example.com/audio/harvest-song.mp3',
    timezone('utc'::text, now())
);

-- Track for public listening
INSERT INTO public.music_tracks (title, description, notes, audio_url, created_at)
VALUES (
    'أغنية الطريق',
    'أغنية ملاحية مشهورة',
    'ري - مي - Fa - Sol',
    'https://example.com/audio/road-song.mp3',
    timezone('utc'::text, now())
);