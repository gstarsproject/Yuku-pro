INSERT INTO "Category" ("id", "name", "slug", "pillar", "isActive") VALUES
(gen_random_uuid(), 'Teman Ngobrol', 'teman-ngobrol', 'FRIEND', true),
(gen_random_uuid(), 'Teman Jalan', 'teman-jalan', 'FRIEND', true),
(gen_random_uuid(), 'Teman Makan', 'teman-makan', 'FRIEND', true),
(gen_random_uuid(), 'Tour Guide', 'tour-guide', 'EXPERIENCE', true),
(gen_random_uuid(), 'Local Guide', 'local-guide', 'EXPERIENCE', true),
(gen_random_uuid(), 'Fotografi Wisata', 'fotografi-wisata', 'EXPERIENCE', true),
(gen_random_uuid(), 'Tutor', 'tutor', 'PRO', true),
(gen_random_uuid(), 'Desain Grafis', 'desain-grafis', 'PRO', true),
(gen_random_uuid(), 'Penerjemah', 'penerjemah', 'PRO', true)
ON CONFLICT ("slug") DO NOTHING;
