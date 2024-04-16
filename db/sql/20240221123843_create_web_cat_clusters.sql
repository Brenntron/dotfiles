-- Create new table
CREATE TABLE web_cat_clusters (
    id SERIAL PRIMARY KEY,
    domain VARCHAR(255),
    description TEXT,
    platform_id INTEGER,
    category_ids VARCHAR(255),
    status INTEGER DEFAULT 0, -- Set default value for status
    traffic_hits INTEGER DEFAULT 0, -- Set default value for traffic_hits
    comment VARCHAR(255),
    cluster_type VARCHAR(255),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
-- Add index to new table
ALTER TABLE web_cat_clusters ADD INDEX idx_web_cat_clusters_cluster_type (cluster_type);

-- populate new table
INSERT INTO web_cat_clusters (domain, platform_id, category_ids, status, traffic_hits, comment, cluster_type, created_at, updated_at)
SELECT domain, platform_id, category_ids, status, traffic_hits, comment, 'Umbrella' AS cluster_type, created_at, updated_at FROM umbrella_clusters;

INSERT INTO web_cat_clusters (domain, platform_id, category_ids, status, traffic_hits, comment, cluster_type, created_at, updated_at)
SELECT domain, platform_id, category_ids, status, traffic_hits, comment, 'NGFW' AS cluster_type, created_at, updated_at FROM ngfw_clusters;

INSERT INTO web_cat_clusters (domain, platform_id, category_ids, status, traffic_hits, comment, cluster_type, created_at, updated_at)
SELECT domain, platform_id, category_ids, status, traffic_hits, comment, 'Meraki' AS cluster_type, created_at, updated_at FROM meraki_clusters;

-- Insert timestamp into schema_migrations
INSERT INTO `schema_migrations` (`version`) VALUES ('20240221123843');
INSERT INTO `schema_migrations` (`version`) VALUES ('20240415170056');
