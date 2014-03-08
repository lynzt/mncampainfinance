DROP DATABASE IF EXISTS mn_campaign_finance;
CREATE DATABASE IF NOT EXISTS mn_campaign_finance;

-- DROP DATABASE IF EXISTS common;
-- CREATE DATABASE IF NOT EXISTS common;

-- DROP USER  'mncf_admin'@'localhost'; 
-- CREATE USER 'mncf_admin'@'localhost' IDENTIFIED BY 'dnest123';
-- GRANT ALL PRIVILEGES ON mn_campaign_finance.* TO 'mncf_admin'@'localhost';

#  ########    ###    ########  ##       ########  ######  
#     ##      ## ##   ##     ## ##       ##       ##    ## 
#     ##     ##   ##  ##     ## ##       ##       ##       
#     ##    ##     ## ########  ##       ######    ######  
#     ##    ######### ##     ## ##       ##             ## 
#     ##    ##     ## ##     ## ##       ##       ##    ## 
#     ##    ##     ## ########  ######## ########  ######  
DROP TABLE IF EXISTS mn_campaign_finance.lobbyists;
CREATE TABLE mn_campaign_finance.lobbyists (
	registration_number MEDIUMINT UNSIGNED NOT NULL
	, first_name VARCHAR(56) NULL
	, middle_name VARCHAR(56) NULL
	, last_name VARCHAR(56) NULL
	, nick_name VARCHAR(56) NULL
	, long_name VARCHAR(224) NULL
	, principal_business VARCHA(128) NULL
	, phone VARCHAR(32) NULL
	, email VARCHAR(128) NULL
	, email_lookup VARCHAR(128) NULL -- email reversed
	, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
	, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	-- Required Keys
	, PRIMARY KEY  pk_registration_number (registration_number)
) ENGINE = InnoDB DEFAULT CHARSET=utf8;
-- ALTER TABLE mn_campaign_finance.lobbyists ADD COLUMN `principal_business` VARCHAR(128) NULL after long_name;



-- DROP TABLE IF EXISTS mn_campaign_finance.companies;
-- CREATE TABLE mn_campaign_finance.companies (
-- 	id INT UNSIGNED NOT NULL AUTO_INCREMENT
-- 	, type ENUM('bus', 'ind')
-- 	, name VARCHAR(255) NULL
-- 	-- , alternate_name VARCHAR(255) NULL
-- 	-- , url VARCHAR(56) NULL
-- 	-- , street1 VARCHAR(128) NULL
-- 	-- , street2 VARCHAR(128) NULL
-- 	-- , city VARCHAR(128) NULL
-- 	-- , region VARCHAR(2) NULL
-- 	-- , zip VARCHAR(10) NULL
-- 	-- , zip_4_code CHAR(4) NULL
-- 	-- , country VARCHAR(128) NULL
-- 	-- , full_address VARCHAR (255) NULL
-- 	, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
-- 	, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
-- 	-- Required Keys
-- 	, PRIMARY KEY  pk_id (id)
-- ) ENGINE = InnoDB DEFAULT CHARSET=utf8;
-- ALTER TABLE mn_campaign_finance.companies ADD COLUMN `registration_number` registration_number MEDIUMINT UNSIGNED NOT NULL after id;


DROP TABLE IF EXISTS mn_campaign_finance.associations$contacts;
CREATE TABLE mn_campaign_finance.associations$contacts (
	association_number MEDIUMINT UNSIGNED NOT NULL
	, year SMALLINT UNSIGNED NULL
	, first_name VARCHAR(56) NULL
	, middle_name VARCHAR(56) NULL
	, last_name VARCHAR(56) NULL
	, nick_name VARCHAR(56) NULL
	, long_name VARCHAR(224) NULL
	, title VARCHAR(128) NULL
	, phone VARCHAR(32) NULL
	, email VARCHAR(128) NULL
	, email_lookup VARCHAR(128) NULL -- email reversed
	, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
	, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	-- Required Keys
	, PRIMARY KEY  pk_company_id (association_number, year)
) ENGINE = InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS mn_campaign_finance.associations;
CREATE TABLE mn_campaign_finance.associations (
	association_number MEDIUMINT UNSIGNED NOT NULL
	, name VARCHAR(255) NULL
	, alternate_name VARCHAR(255) NULL
	, url VARCHAR(128) NULL
	, street1 VARCHAR(128) NULL
	, street2 VARCHAR(128) NULL
	, city VARCHAR(128) NULL
	, region VARCHAR(2) NULL
	, zip VARCHAR(10) NULL
	, zip_4_code CHAR(4) NULL
	, country VARCHAR(128) NULL
	, full_address VARCHAR(255) NULL
	, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
	, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	-- Required Keys
	, PRIMARY KEY pk_association_number (association_number)
) ENGINE = InnoDB DEFAULT CHARSET=utf8;




DROP TABLE IF EXISTS mn_campaign_finance.associations$lobbyists;
CREATE TABLE mn_campaign_finance.associations$lobbyists (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT
	, association_number MEDIUMINT UNSIGNED NOT NULL
	, registration_number MEDIUMINT UNSIGNED NOT NULL
	, registration_date DATETIME NOT NULL
	, termination_date DATETIME NULL
	, is_legislative bool NULL
	, is_administrative bool NULL
	, is_metropolitan bool NULL
	, is_designated_lobbyist bool NULL
	, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
	, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	-- Required Keys
	, PRIMARY KEY pk_id (id)
) ENGINE = InnoDB DEFAULT CHARSET=utf8;
id INT UNSIGNED NOT NULL AUTO_INCREMENT

CREATE INDEX idx_pk ON associations$lobbyists(association_number, registration_number, registration_date);
ALTER TABLE mn_campaign_finance.associations$lobbyists ADD COLUMN `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY after s;



DROP TABLE IF EXISTS mn_campaign_finance.addresses;
CREATE TABLE mn_campaign_finance.addresses (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT
	, street1 VARCHAR(128) NULL
	, street2 VARCHAR(128) NULL
	, city VARCHAR(128) NULL
	, region VARCHAR(2) NULL
	, zip VARCHAR(10) NULL
	, zip_4_code CHAR(4) NULL
	, country VARCHAR(128) NULL
	, full_address VARCHAR (255) NULL
	, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
	, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	-- Required Keys
	, PRIMARY KEY  pk_id (id)
) ENGINE = InnoDB DEFAULT CHARSET=utf8;
CREATE INDEX idx_Address ON addresses(full_address(20));


DROP TABLE IF EXISTS mn_campaign_finance.associations$addresses;
CREATE TABLE mn_campaign_finance.associations$addresses (
	type ENUM('l', 'a') NOT NULL
	, type_id MEDIUMINT UNSIGNED NOT NULL
	, address_id INT UNSIGNED NOT NULL
	-- , year SMALLINT UNSIGNED NULL
	, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
	, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	-- Required Keys
	, PRIMARY KEY  pk_id (type, type_id, address_id)
) ENGINE = InnoDB DEFAULT CHARSET=utf8;


-- DROP TABLE IF EXISTS common.us_zipcodes;
-- CREATE TABLE common.us_zipcodes (
-- 	zip_code CHAR(5) NOT NULL
-- 	, type ENUM('STANDARD', 'PO BOX', 'UNIQUE', 'MILITARY') NOT NULL
-- 	, primary_city VARCHAR(128) NULL
-- 	, region VARCHAR(128) NULL
-- 	, region_abbreviation CHAR(2) NULL
-- 	, county VARCHAR(128) NULL
-- 	, estimated_population INT UNSIGNED NULL	
-- 	, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
-- 	, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
-- 	-- Required Keys
-- 	, PRIMARY KEY pk_id (zip_code)
-- ) ENGINE = InnoDB DEFAULT CHARSET=utf8;