-- Chapter 2 | Step 1: explicit mapping table for seller city labels.
-- SQL Server. Creates ONE new table (dbo.seller_city_map); the raw sellers table is NOT modified.
-- The mapping is applied only when reading: join sellers.seller_city to raw_city (and raw_state when it is set).
-- status: corrected   = label text fixed (state and ZIP reference agree)
--         unresolved  = not a usable city name, or ambiguous: clean city left NULL
--         kept        = reference table quirk, original value kept
-- Abbreviations marked "to confirm" (sbc) are interpretations supported by the ZIP reference.
-- Rule 5 (no row here): a valid city label whose ZIP prefix belongs to another municipality (26 sellers)
-- is left as registered and documented in 16_chapter2_geography_audit.sql, query 6.
-- Results of the checks at the end, executed in SSMS by the analyst on 20 Oct 2026:
--   CHECK A (labels): 56 corrected | 15 unresolved | 2 kept = 73 labels
--   CHECK B (sellers): 66 corrected | 18 unresolved | 2 kept = 86 sellers
--   CHECK C: 0 rows (every correction agrees with the ZIP reference city)
--   BEFORE/AFTER: labels 611 -> 548 | city+state pairs 636 -> 572 (unresolved labels are excluded from 'after').
-- Cross-check: 611 - 56 - 14 + 7 = 548 and 636 - 56 - 15 + 7 = 572, where 7 is the number of standard
-- spellings that did not exist as labels before (inferred from the counts, not listed one by one).
-- Version note: the e-mail row is now inserted by pattern; the logic is otherwise the executed version 5.
USE olist;
GO

DROP TABLE IF EXISTS dbo.seller_city_map;

CREATE TABLE dbo.seller_city_map (
    raw_city   VARCHAR(100) NOT NULL PRIMARY KEY,
    raw_state  CHAR(2)      NULL,   -- NULL = applies to every state; otherwise only to that registered state
    clean_city VARCHAR(100) NULL,
    status     VARCHAR(12)  NOT NULL,
    fix_type   VARCHAR(60)  NOT NULL
);
GO
-- (GO ends the first batch so the new table exists before the rest of the script is compiled.)

-- 1) Corrected labels (53 ASCII labels)
INSERT INTO dbo.seller_city_map (raw_city, clean_city, status, fix_type) VALUES
('angra dos reis rj',                         'angra dos reis',          'corrected', 'state suffix'),
('ao bernardo do campo',                      'sao bernardo do campo',   'corrected', 'typo'),
('arraial d''ajuda (porto seguro)',           'arraial d''ajuda',        'corrected', 'extra text'),
('auriflama/sp',                              'auriflama',               'corrected', 'state suffix'),
('balenario camboriu',                        'balneario camboriu',      'corrected', 'typo'),
('barbacena/ minas gerais',                   'barbacena',               'corrected', 'state name suffix'),
('belo horizont',                             'belo horizonte',          'corrected', 'typo'),
('brasilia df',                               'brasilia',                'corrected', 'state suffix'),
('carapicuiba / sao paulo',                   'carapicuiba',             'corrected', 'state name suffix'),
('cariacica / es',                            'cariacica',               'corrected', 'state suffix'),
('cascavael',                                 'cascavel',                'corrected', 'typo'),
('ferraz de  vasconcelos',                    'ferraz de vasconcelos',   'corrected', 'double space'),
('floranopolis',                              'florianopolis',           'corrected', 'typo'),
('garulhos',                                  'guarulhos',               'corrected', 'typo'),
('jacarei / sao paulo',                       'jacarei',                 'corrected', 'state name suffix'),
('ji parana',                                 'ji-parana',               'corrected', 'hyphen'),
('juzeiro do norte',                          'juazeiro do norte',       'corrected', 'typo'),
('lages - sc',                                'lages',                   'corrected', 'state suffix'),
('maua/sao paulo',                            'maua',                    'corrected', 'state name suffix'),
('mogi das cruses',                           'mogi das cruzes',         'corrected', 'typo'),
('mogi das cruzes / sp',                      'mogi das cruzes',         'corrected', 'state suffix'),
('novo hamburgo, rio grande do sul, brasil',  'novo hamburgo',           'corrected', 'state and country suffix'),
('paincandu',                                 'paicandu',                'corrected', 'typo (reference spelling)'),
('pinhais/pr',                                'pinhais',                 'corrected', 'state suffix'),
('portoferreira',                             'porto ferreira',          'corrected', 'typo'),
('ribeirao preto / sao paulo',                'ribeirao preto',          'corrected', 'state name suffix'),
('ribeirao pretp',                            'ribeirao preto',          'corrected', 'typo'),
('riberao preto',                             'ribeirao preto',          'corrected', 'typo'),
('rio de janeiro / rio de janeiro',           'rio de janeiro',          'corrected', 'duplicated name'),
('rio de janeiro \rio de janeiro',            'rio de janeiro',          'corrected', 'duplicated name'),
('robeirao preto',                            'ribeirao preto',          'corrected', 'typo'),
('s jose do rio preto',                       'sao jose do rio preto',   'corrected', 'abbreviation'),
('sando andre',                               'santo andre',             'corrected', 'typo'),
('santo andre/sao paulo',                     'santo andre',             'corrected', 'state name suffix'),
('sao  jose dos pinhais',                     'sao jose dos pinhais',    'corrected', 'double space'),
('sao  paulo',                                'sao paulo',               'corrected', 'double space'),
('sao bernardo do capo',                      'sao bernardo do campo',   'corrected', 'typo'),
('sao jose do rio pret',                      'sao jose do rio preto',   'corrected', 'truncated'),
('sao jose dos pinhas',                       'sao jose dos pinhais',    'corrected', 'typo'),
('sao paluo',                                 'sao paulo',               'corrected', 'typo'),
('sao paulo - sp',                            'sao paulo',               'corrected', 'state suffix'),
('sao paulo / sao paulo',                     'sao paulo',               'corrected', 'duplicated name'),
('sao paulo sp',                              'sao paulo',               'corrected', 'state suffix'),
('sao paulop',                                'sao paulo',               'corrected', 'typo'),
('sao pauo',                                  'sao paulo',               'corrected', 'typo'),
('sao sebastiao da grama/sp',                 'sao sebastiao da grama',  'corrected', 'state suffix'),
('sbc',                                       'sao bernardo do campo',   'corrected', 'abbreviation (to confirm)'),
('sbc/sp',                                    'sao bernardo do campo',   'corrected', 'abbreviation (to confirm)'),
('scao jose do rio pardo',                    'sao jose do rio pardo',   'corrected', 'typo'),
('tabao da serra',                            'taboao da serra',         'corrected', 'typo'),
('mogi guacu',                                'mogi-guacu',              'corrected', 'hyphen'),
('embu guacu',                                'embu-guacu',              'corrected', 'hyphen'),
('rio de janeiro, rio de janeiro, brasil',    'rio de janeiro',          'corrected', 'duplicated name and country');

-- 2) Corrupted-encoding / spelling-variant labels (3 labels: sa..o paulo, santa barbara d-..oeste, santa barbara d oeste). Matched with LIKE so no special character has to be typed.
INSERT INTO dbo.seller_city_map (raw_city, clean_city, status, fix_type)
SELECT DISTINCT seller_city, 'sao paulo', 'corrected', 'encoding'
FROM sellers
WHERE seller_city LIKE 'sa%o paulo' AND seller_city <> 'sao paulo'
  AND seller_city NOT IN (SELECT raw_city FROM dbo.seller_city_map);

INSERT INTO dbo.seller_city_map (raw_city, clean_city, status, fix_type)
SELECT DISTINCT seller_city, 'santa barbara d''oeste', 'corrected', 'encoding'
FROM sellers
WHERE seller_city LIKE 'santa barbara d%oeste' AND seller_city <> 'santa barbara d''oeste'
  AND seller_city NOT IN (SELECT raw_city FROM dbo.seller_city_map);

-- 3) Unresolved labels (15): not a city name, or ambiguous. Clean city stays NULL.
INSERT INTO dbo.seller_city_map (raw_city, clean_city, status, fix_type) VALUES
('04482255',                    NULL, 'unresolved', 'number, not a city'),
('aguas claras df',             NULL, 'unresolved', 'ambiguous, state conflict'),
('andira-pr',                   NULL, 'unresolved', 'ZIP reference gives another city'),
('bahia',                       NULL, 'unresolved', 'state name'),
('castro pires',                NULL, 'unresolved', 'ZIP reference gives another city'),
('centro',                      NULL, 'unresolved', 'generic word'),
('minas gerais',                NULL, 'unresolved', 'state name'),
('parana',                      NULL, 'unresolved', 'state name'),
('pirituba',                    NULL, 'unresolved', 'possible district'),
('rio bonito',                  NULL, 'unresolved', 'ZIP reference gives another city'),
('santa catarina',              NULL, 'unresolved', 'state name'),
('sp / sp',                     NULL, 'unresolved', 'state twice, not a city'),
('vicente de carvalho',         NULL, 'unresolved', 'possible district'),
('sp',                          NULL, 'unresolved', 'state abbreviation, not a city');

-- One label is an e-mail address typed into the city field. It is matched by pattern so that no personal
-- or business address is published in this repository.
INSERT INTO dbo.seller_city_map (raw_city, clean_city, status, fix_type)
SELECT DISTINCT seller_city, NULL, 'unresolved', 'e-mail address'
FROM sellers
WHERE seller_city LIKE '%@%'
  AND seller_city NOT IN (SELECT raw_city FROM dbo.seller_city_map);

-- 'rio bonito' is ambiguous only for the seller registered in SP (ZIP prefix 28810, RJ area).
-- Another seller registered in RJ (ZIP 28800) has a valid pair and must NOT be touched.
UPDATE dbo.seller_city_map SET raw_state = 'SP' WHERE raw_city = 'rio bonito';

-- 4) Reference-table quirks (2): original value kept.
INSERT INTO dbo.seller_city_map (raw_city, clean_city, status, fix_type) VALUES
('brejao',            'brejao',            'kept', 'reference shows corrupted encoding'),
('sao miguel d''oeste','sao miguel d''oeste','kept', 'reference spells "do oeste"');

-- CHECK A: what was inserted, by status (expected 56 corrected, 15 unresolved, 2 kept = 73 labels).
SELECT status, COUNT(*) AS labels FROM dbo.seller_city_map GROUP BY status ORDER BY status;

-- CHECK B: sellers covered, by status (expected 66 corrected, 18 unresolved, 2 kept = 86 sellers).
SELECT M.status, COUNT(*) AS sellers
FROM sellers AS S
JOIN dbo.seller_city_map AS M ON M.raw_city = S.seller_city AND (M.raw_state IS NULL OR M.raw_state = S.seller_state)
GROUP BY M.status ORDER BY M.status;

-- CHECK C: every corrected label must agree with the ZIP reference. Expected: 0 rows.
;WITH Z AS (
    SELECT geolocation_zip_code_prefix AS zip,
           geolocation_city AS ref_city,
           ROW_NUMBER() OVER (
               PARTITION BY geolocation_zip_code_prefix
               ORDER BY COUNT(*) DESC, geolocation_city) AS rk
    FROM geolocation
    GROUP BY geolocation_zip_code_prefix, geolocation_city, geolocation_state
)
SELECT M.raw_city, M.clean_city, Z.ref_city, S.seller_zip_code_prefix
FROM sellers AS S
JOIN dbo.seller_city_map AS M ON M.raw_city = S.seller_city AND (M.raw_state IS NULL OR M.raw_state = S.seller_state) AND M.status = 'corrected'
LEFT JOIN Z ON Z.zip = S.seller_zip_code_prefix AND Z.rk = 1
WHERE Z.ref_city IS NULL OR Z.ref_city <> M.clean_city;

-- BEFORE / AFTER: distinct city labels and city+state pairs (before: 611 labels, 636 pairs).
SELECT COUNT(DISTINCT S.seller_city) AS labels_before,
       COUNT(DISTINCT CASE WHEN M.status = 'unresolved' THEN NULL
                           ELSE COALESCE(M.clean_city, S.seller_city) END) AS labels_after,
       COUNT(DISTINCT S.seller_city + '|' + S.seller_state) AS pairs_before,
       COUNT(DISTINCT CASE WHEN M.status = 'unresolved' THEN NULL
                           ELSE COALESCE(M.clean_city, S.seller_city) + '|' + S.seller_state END) AS pairs_after
FROM sellers AS S
LEFT JOIN dbo.seller_city_map AS M ON M.raw_city = S.seller_city AND (M.raw_state IS NULL OR M.raw_state = S.seller_state);
