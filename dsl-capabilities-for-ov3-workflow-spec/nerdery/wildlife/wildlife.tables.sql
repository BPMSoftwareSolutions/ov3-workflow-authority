-- The wildlife domain store of the Nerdery citizen slice, schema wildlife in the sfx-identity database.
-- Identities are case sensitive (BIN2); email is unique without regard to case. The canonical JSON columns hold exactly
-- what a read returns (range, types, stats, attribute associations), and the association tables carry their
-- references for integrity and indexing. A photo's bytes are kept with it, addressed by their sha256.
-- Sign-in: identity_response is the stand-in for the DNR identity service, the responses it would return by reference
-- (D02; a real integration validates a signed DNR response on the server). signed_in_session is the wildlife user a
-- verified SideFX session signed in as through DNR; roles stay with the user, assigned outside the application.
CREATE TABLE wildlife.app_user(
  user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  principal_id uniqueidentifier NULL,
  identity_subject nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL UNIQUE,
  first_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  last_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  email nvarchar(320) COLLATE Latin1_General_100_CI_AS NOT NULL UNIQUE);
CREATE UNIQUE INDEX UX_wildlife_app_user_principal ON wildlife.app_user(principal_id) WHERE principal_id IS NOT NULL;
CREATE TABLE wildlife.user_role(
  user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  role nvarchar(40) COLLATE Latin1_General_100_BIN2 NOT NULL,
  PRIMARY KEY(user_id,role));
CREATE TABLE wildlife.county(
  county_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL);
CREATE TABLE wildlife.animal_type(
  type_name nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  ordinal int NOT NULL);
CREATE TABLE wildlife.attribute(
  attribute_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  revision int NOT NULL,
  active bit NOT NULL,
  name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  description nvarchar(2000) COLLATE Latin1_General_100_BIN2 NOT NULL);
CREATE TABLE wildlife.attribute_value(
  attribute_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  value_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  label nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  ordinal int NOT NULL,
  PRIMARY KEY(attribute_id,value_id));
CREATE TABLE wildlife.animal_definition(
  definition_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  revision int NOT NULL,
  active bit NOT NULL,
  common_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  scientific_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  avatar_photo_ref nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  collection_number int NOT NULL UNIQUE,
  range_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
  types_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
  stats_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
  attributes_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
CREATE TABLE wildlife.definition_county(
  definition_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  county_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  PRIMARY KEY(definition_id,county_id));
CREATE TABLE wildlife.definition_type(
  definition_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  type_name nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  PRIMARY KEY(definition_id,type_name));
CREATE TABLE wildlife.definition_attribute_value(
  definition_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  attribute_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  value_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  PRIMARY KEY(definition_id,attribute_id,value_id));
CREATE TABLE wildlife.photo(
  photo_ref nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  owner_user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,
  purpose nvarchar(20) COLLATE Latin1_General_100_BIN2 NOT NULL,
  media_type nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  content_sha256 binary(32) NOT NULL,
  content_bytes varbinary(max) NULL,
  byte_length bigint NULL,
  durable bit NOT NULL);
CREATE TABLE wildlife.encounter(
  owner_user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  encounter_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  definition_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  location_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
  photo_ref nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  nickname nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,
  PRIMARY KEY(owner_user_id,encounter_id));
CREATE TABLE wildlife.team(
  owner_user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  revision int NOT NULL);
CREATE TABLE wildlife.team_member(
  owner_user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  ordinal int NOT NULL,
  encounter_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  PRIMARY KEY(owner_user_id,ordinal),
  UNIQUE(owner_user_id,encounter_id));
CREATE TABLE wildlife.identity_response(
  response_ref nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  validation nvarchar(20) COLLATE Latin1_General_100_BIN2 NOT NULL,
  subject nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,
  first_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,
  last_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,
  email nvarchar(320) COLLATE Latin1_General_100_CI_AS NULL,
  roles_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
CREATE TABLE wildlife.signed_in_session(
  session_id uniqueidentifier NOT NULL PRIMARY KEY,
  user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  signed_in_at datetime2(3) NOT NULL);
