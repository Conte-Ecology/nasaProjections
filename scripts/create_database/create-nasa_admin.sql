CREATE ROLE nasa_admin NOLOGIN INHERIT;

-- public SCHEMA
GRANT ALL ON SCHEMA public TO nasa_admin;
GRANT ALL ON ALL TABLES IN SCHEMA public TO nasa_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO nasa_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO nasa_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO nasa_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO nasa_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO nasa_admin;

-- data SCHEMA
GRANT ALL ON SCHEMA data TO nasa_admin;
GRANT ALL ON ALL TABLES IN SCHEMA data TO nasa_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA data TO nasa_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA data TO nasa_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA data GRANT ALL ON TABLES TO nasa_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA data GRANT ALL ON SEQUENCES TO nasa_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA data GRANT ALL ON FUNCTIONS TO nasa_admin;