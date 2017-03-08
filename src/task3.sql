
CREATE TABLE Countries (
  name TEXT NOT NULL PRIMARY KEY
);

CREATE TABLE Areas(
  country TEXT NOT NULL,
  name TEXT NOT NULL,
  population NUMERIC NOT NULL CHECK (population >= 0) DEFAULT (0),
  PRIMARY KEY (name, country),
  FOREIGN KEY (country) REFERENCES Countries(name) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Towns (
  country TEXT NOT NULL ,
  name TEXT NOT NULL ,
  PRIMARY KEY (name, country),
  FOREIGN KEY (name, country) REFERENCES Areas (name, country) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Cities (
  country TEXT NOT NULL ,
  name TEXT NOT NULL ,
  visitbonus NUMERIC NOT NULL CHECK (visitbonus >= 0) DEFAULT (0),
  PRIMARY KEY (name, country),
  FOREIGN KEY (name, country) REFERENCES Areas (name, country) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Persons (
  country TEXT NOT NULL,
  personnummer VARCHAR(13) NOT NULL
  CHECK(
    (
    personnummer ~ '^\d{8}-\d{4}$'
    OR (personnummer  ~ '^ $' AND country ~ '^ $')
    OR (personnummer  ~ '^$' AND country ~ '^$')
    )
  ) ,
  name TEXT NOT NULL,
  locationcountry TEXT NOT NULL,
  locationarea TEXT NOT NULL,
  budget NUMERIC NOT NULL CHECK (budget >= 0) DEFAULT (0),
  PRIMARY KEY (country, personnummer),
  FOREIGN KEY (country) REFERENCES Countries(name) ON DELETE CASCADE ON UPDATE CASCADE ,
  FOREIGN KEY (locationcountry, locationarea) REFERENCES Areas(country, name)
);

CREATE TABLE Hotels (
  name TEXT NOT NULL ,
  locationcountry TEXT NOT NULL,
  locationname TEXT NOT NULL,
  ownercountry TEXT NOT NULL,
  ownerpersonnummer VARCHAR(13) ,
  PRIMARY KEY (locationcountry, locationname, ownercountry, ownerpersonnummer),
  FOREIGN KEY (ownercountry, ownerpersonnummer) REFERENCES Persons(country, personnummer)ON DELETE CASCADE ON UPDATE CASCADE ,
  FOREIGN KEY (locationcountry, locationname) REFERENCES Cities(country, name)ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Roads (
  fromcountry TEXT NOT NULL,
  fromarea TEXT NOT NULL,
  tocountry TEXT NOT NULL,
  toarea TEXT NOT NULL,
  ownercountry TEXT NOT NULL,
  ownerpersonnummer VARCHAR(13) ,
  roadtax NUMERIC NOT NULL  CHECK (roadtax >= 0) DEFAULT (getval('roadtax')),
  PRIMARY KEY (fromcountry, fromarea, tocountry, toarea, ownercountry, ownerpersonnummer),
  FOREIGN KEY (ownercountry, ownerpersonnummer) REFERENCES Persons(country, personnummer)ON DELETE CASCADE ON UPDATE CASCADE ,
  FOREIGN KEY (fromcountry, fromarea) REFERENCES Areas(country, name)ON DELETE CASCADE ON UPDATE CASCADE ,
  FOREIGN KEY (tocountry, toarea) REFERENCES Areas(country, name)ON DELETE CASCADE ON UPDATE CASCADE
);




CREATE OR REPLACE VIEW NextMoves AS (
    SELECT country AS personcountry,
      personnummer,
      locationcountry AS country,
      locationarea AS area,
      destcountry,
      destarea,
      MIN(cost) AS cost
    FROM(
        (SELECT
            p.country,
            p.personnummer,
            p.locationcountry,
            p.locationarea,
            r.fromcountry AS destcountry,
            r.fromarea    AS destarea,
            r.roadtax     AS cost
        FROM  Persons p , Roads r
        WHERE p.budget >= r.roadtax
              AND p.locationarea = r.toarea
              AND p.locationcountry = r.tocountry
              AND (p.country != ''
              AND p.personnummer != '')
              AND (p.country != ' '
              AND p.personnummer != ' '))
    UNION
        (SELECT
            p.country,
            p.personnummer,
            p.locationcountry,
            p.locationarea,
            r.tocountry AS destcountry,
            r.toarea    AS destarea,
            r.roadtax   AS cost
        FROM  Persons p, Roads r
        WHERE p.budget >= r.roadtax
              AND p.locationarea = r.fromarea
              AND p.locationcountry = r.fromcountry
              AND (p.country != ''
              AND p.personnummer != '')
              AND (p.country != ' '
              AND p.personnummer != ' '))
    UNION
        (SELECT
            p.country,
            p.personnummer,
            p.locationcountry,
            p.locationarea,
            r.tocountry AS destcountry,
            r.toarea    AS destarea,
            0   AS cost
        FROM  Persons p, Roads r
        WHERE  p.country = r.ownercountry
            AND p.personnummer = r.ownerpersonnummer
            AND p.locationarea = r.fromarea
            AND p.locationcountry = r.fromcountry
            AND (p.country != ''
            AND p.personnummer != '')
            AND (p.country != ' '
            AND p.personnummer != ' '))

    UNION
        (SELECT
            p.country,
            p.personnummer,
            p.locationcountry,
            p.locationarea,
            r.fromcountry AS destcountry,
            r.fromarea    AS destarea,
            0   AS cost
        FROM Persons p, Roads r
        WHERE  p.country = r.ownercountry
            AND p.personnummer = r.ownerpersonnummer
            AND p.locationarea = r.toarea
            AND p.locationcountry = r.tocountry
            AND (p.country != ''
            AND p.personnummer != '')
            AND (p.country != ' '
            AND p.personnummer != ' '))) AS huehue
    GROUP BY country,
    personnummer,
    locationcountry,
    locationarea,
    destcountry,
    destarea
);

CREATE OR REPLACE VIEW AssetSummary AS(
  SELECT country, personnummer, budget,
  (
    (SELECT (COUNT(name)*getval('hotelprice'))
    FROM Hotels
    WHERE ownercountry = country
      AND ownerpersonnummer = personnummer)
      +
    (SELECT (COUNT(roadtax)*getval('roadprice'))
    FROM Roads
    WHERE ownercountry = country
      AND ownerpersonnummer = personnummer)
  ) AS assets,

  (
    SELECT (COUNT(name)*getval('hotelprice')*getval('hotelrefund')) AS huehuehue
    FROM Hotels
    WHERE ownercountry = country
      AND ownerpersonnummer = personnummer
  ) AS reclaimable
  FROM Persons
  WHERE country != ''
    AND personnummer != ''
    AND country != ' '
    AND personnummer != ' '
  GROUP BY country, personnummer, budget
);

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--When a road (A->B) is added/deleted, you must ensure that the reverse road(B->A) is not already present for the same owner.
--BEGIN Roads:

CREATE OR REPLACE FUNCTION check_road_insert_ok() RETURNS TRIGGER AS $$
DECLARE
  alreadyexisting BOOLEAN;
  ownerisatethierplace BOOLEAN;
  ownerhasmoney BOOLEAN;
  isGovernmentRoad BOOLEAN;
  theNewBudget NUMERIC;
BEGIN
  IF(NEW.fromcountry = NEW.tocountry AND NEW.fromarea = NEW.toarea) THEN
    RAISE EXCEPTION 'Roads that circle back arnt allowed!';
  END IF;
  alreadyexisting :=(
    EXISTS(
      (SELECT ownerpersonnummer
      FROM Roads
      WHERE tocountry = NEW.fromcountry
        AND toarea = NEW.fromarea
        AND fromcountry = NEW.tocountry
        AND fromarea = NEW.toarea
        AND ownercountry = NEW.ownercountry
        AND ownerpersonnummer = NEW.ownerpersonnummer)
      UNION
      (SELECT ownerpersonnummer
      FROM Roads
      WHERE fromcountry = NEW.fromcountry
        AND fromarea = NEW.fromarea
        AND tocountry = NEW.tocountry
        AND toarea = NEW.toarea
        AND ownercountry = NEW.ownercountry
        AND ownerpersonnummer = NEW.ownerpersonnummer)
    )
  );

  If (alreadyexisting) THEN
    RAISE EXCEPTION 'Road already exist with the same owner';
  ELSE
    isGovernmentRoad :=(
      (NEW.ownercountry ~ '^ $'
      AND NEW.ownerpersonnummer ~ '^ $')
      OR
      (NEW.ownercountry ~ '^$'
      AND NEW.ownerpersonnummer ~ '^$')
    );
    if(isGovernmentRoad)THEN
      RETURN NEW;
    END IF;
    ownerisatethierplace :=(
      EXISTS(
        (SELECT personnummer
        FROM Persons
        WHERE locationcountry = NEW.fromcountry
          AND locationarea = NEW.fromarea
          AND country = NEW.ownercountry
          AND personnummer = NEW.ownerpersonnummer)
        UNION
        (SELECT personnummer
        FROM Persons
        WHERE locationcountry = NEW.tocountry
          AND locationarea = NEW.toarea
          AND country = NEW.ownercountry
          AND personnummer = NEW.ownerpersonnummer)
      )
    );

    IF(NOT ownerisatethierplace) THEN
      RAISE EXCEPTION 'That person isnt located in ether of those cities!';
    ELSE
      ownerhasmoney :=(
        (SELECT budget
        FROM Persons
        WHERE country = NEW.ownercountry
          AND personnummer = NEW.ownerpersonnummer)
        >=
        getval('roadprice')
      );

      IF( NOT ownerhasmoney ) THEN
        RAISE EXCEPTION 'That person doesnt have enough money!';
      ELSE
        UPDATE Persons SET budget = budget - getval('roadprice')
        WHERE country = NEW.ownercountry
              AND personnummer = NEW.ownerpersonnummer;
        RETURN NEW;
      END IF;
    END IF;
  END IF;
END
$$ LANGUAGE 'plpgsql';


DROP TRIGGER IF EXISTS TryInsertNewRoad ON Roads;

CREATE TRIGGER TryInsertNewRoad BEFORE INSERT ON Roads
FOR EACH ROW
EXECUTE PROCEDURE check_road_insert_ok();

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION is_road_update_ok() RETURNS TRIGGER AS $$
DECLARE
  onlyroadtaxupdate BOOLEAN;
BEGIN
  onlyroadtaxupdate :=(
    NEW.ownercountry = OLD.ownercountry
    AND NEW.ownerpersonnummer = OLD.ownerpersonnummer
    AND NEW.fromarea = OLD.fromarea
    AND NEW.fromcountry = OLD.fromcountry
    AND NEW.toarea = OLD.toarea
    AND NEW.tocountry = OLD.tocountry
    AND NEW.roadtax >= 0
  );
  IF(onlyroadtaxupdate) THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'Only roadtax is allowed to be updated (and > than 0!)';
  END IF;
END;
$$ LANGUAGE 'plpgsql';


DROP TRIGGER IF EXISTS road_update ON Roads;

CREATE TRIGGER road_update BEFORE UPDATE ON Roads
FOR EACH ROW
EXECUTE PROCEDURE is_road_update_ok();



--------------------------------------------------------------------------------'
--------------------------------------------------------------------------------'
--------------------------------------------------------------------------------'
--------------------------------------------------------------------------------'
--------------------------------------------------------------------------------'
--------------------------------------------------------------------------------'
--------------------------------------------------------------------------------'
--------------------------------------------------------------------------------'
--------------------------------------------------------------------------------'
--------------------------------------------------------------------------------'


CREATE OR REPLACE FUNCTION update_person() RETURNS TRIGGER AS $$
DECLARE
  thereIsARoadCost NUMERIC;
  numberOfHotels NUMERIC;
  bonus NUMERIC;
  hotelcost NUMERIC;
  newBudget NUMERIC;
  newCountry TEXT;
  newPersonnummer VARCHAR(13);
  newName TEXT;
  newLocationcountry TEXT;
  newLocationarea TEXT;
BEGIN
 newName := OLD.name;
 newCountry := OLD.country;
 newBudget := NEW.budget;
 newPersonnummer := OLD.personnummer;
 newLocationarea := NEW.locationarea;
 newLocationcountry := NEW.locationcountry;
--Person is trying to traverse the cheapest road from OLD.location to NEW.location is it ok move?
--If this is NOT NULL then there was a road with a cost!
thereIsARoadCost :=(
  SELECT cost
  FROM NextMoves
  WHERE OLD.country = personcountry
    AND OLD.personnummer = personnummer
    AND OLD.locationcountry = country
    AND OLD.locationarea = area
    AND NEW.locationcountry = destcountry
    AND NEW.locationarea = destarea
);
IF( thereIsARoadCost ISNULL ) THEN
  RAISE EXCEPTION 'No such road exist!' ;
END IF;
--Update owner of a road OLD.loc to NEW.loc (and reverse) with adding roadtax to thier budget
IF(thereIsARoadCost > 0) THEN
  UPDATE Persons SET budget = budget + thereIsARoadCost
  WHERE (personnummer, country) IN (
    SELECT ownerpersonnummer, ownercountry
    FROM Roads r
    WHERE (
            (
              (r.fromcountry = newLocationcountry AND r.fromarea = newLocationarea)
              AND (r.tocountry = OLD.locationcountry OR r.toarea = OLD.locationarea)
            )
            OR
            (
              (r.fromcountry = OLD.locationcountry AND r.fromarea = OLD.locationarea)
              AND (r.tocountry = newLocationcountry OR r.toarea = newLocationarea)
            )
          )
      AND roadtax = thereIsARoadCost
    LIMIT 1
  );
  newBudget = newBudget - thereIsARoadCost;
END IF;
--If NEW.location in cities
IF( EXISTS(
  SELECT name
  FROM Cities
  WHERE newLocationcountry = country
    AND newLocationarea = name
) ) THEN
  --Add visitbonus to NEW.budget
  newBudget = newBudget + (
    SELECT visitbonus
    FROM Cities
    WHERE name = newLocationarea
      AND country = newLocationcountry
  );
  --Reset visitbonus
  UPDATE Cities SET visitbonus = 0
  WHERE name = newLocationarea
    AND country = newLocationcountry;
  --If there are hotels
  IF(
    EXISTS(
      SELECT name
      FROM Hotels
      WHERE newLocationcountry = locationcountry
        AND newLocationarea = locationname
    )
  ) THEN
    --Must pay cityvisit price
    newBudget = newBudget - ( getval('cityvisit') );
    --Count number of hotels in city
    numberOfHotels :=(
      SELECT COUNT(name)
      FROM Hotels
      WHERE newLocationcountry = locationcountry
        AND newLocationarea = locationname
    );
    --Pay every owner of a above hotels, in case of NEW = owner, change NEW.budget instead!
    UPDATE Persons SET budget = budget + (getval('cityvisit') / numberOfHotels)
    WHERE (personnummer, country) IN (
      SELECT ownerpersonnummer, ownercountry
      FROM Hotels
      WHERE locationname = newLocationarea
        AND locationcountry = newLocationcountry
        AND (personnummer != newPersonnummer
        OR country != newCountry)
    );

    IF (
      EXISTS(
        SELECT ownerpersonnummer, ownercountry
        FROM Hotels
        WHERE locationname = newLocationarea
          AND locationcountry = newLocationcountry
          AND ownerpersonnummer = newPersonnummer
          AND ownercountry = newCountry
      )
    ) THEN
      newBudget = newBudget + (getval('cityvisit')/numberOfHotels);
    END IF;
  END IF;
END IF;
IF( newBudget < 0 ) THEN
  RAISE EXCEPTION 'Cant afford that!';
END IF;
NEW.name = newName;
NEW.country = newCountry;
NEW.budget = newBudget;
NEW. personnummer = newPersonnummer;
NEW.locationarea = newLocationarea;
NEW.locationcountry = newLocationcountry;
RETURN NEW;

END
$$ LANGUAGE 'plpgsql';



DROP TRIGGER IF EXISTS person_update ON Persons;

CREATE TRIGGER person_update BEFORE UPDATE ON Persons
FOR EACH ROW
WHEN(
  --check if movement & not GOV.
  (OLD.locationcountry != NEW.locationcountry
  OR OLD.locationarea != NEW.locationarea)
  AND
  (
    NOT (
      (OLD.country ~ '^$' AND OLD.personnummer ~ '^$' )
      OR (OLD.country ~ '^ $' AND OLD.personnummer ~ '^ $' )
    )
  )
  AND
  (pg_trigger_depth() < 1)
)
EXECUTE PROCEDURE update_person();

--END Person
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--BEGIN Hotels


CREATE OR REPLACE FUNCTION is_new_hotel_ok() RETURNS TRIGGER AS $$
DECLARE
  ownerallreadyintown BOOLEAN;
  ownerhasmoney BOOLEAN;
BEGIN
  ownerallreadyintown :=(
    EXISTS(
      SELECT ownerpersonnummer
      FROM Hotels
      WHERE locationcountry = NEW.locationcountry
        AND locationname = NEW.locationname
        AND ownercountry = NEW.ownercountry
        AND ownerpersonnummer = NEW.ownerpersonnummer
    )
  );
  IF(ownerallreadyintown) THEN
    RAISE EXCEPTION 'That person already has a hotel in that city';
  ELSE
    ownerhasmoney :=(
      (SELECT budget
       FROM Persons
       WHERE country = NEW.ownercountry
             AND personnummer = NEW.ownerpersonnummer)
      >=
      getval('hotelprice')
    );

    IF( ownerhasmoney ) THEN
      UPDATE Persons SET budget = budget - getval('hotelprice')
      WHERE NEW.ownercountry = country
            AND NEW.ownerpersonnummer = personnummer;
      RETURN NEW;
    ELSE
      RAISE EXCEPTION 'That person doesnt have enough money!';
    END IF;
  END IF;
END;
$$ LANGUAGE 'plpgsql';


DROP TRIGGER IF EXISTS hotel_insertion ON Hotels;

CREATE TRIGGER hotel_insertion BEFORE INSERT ON Hotels
FOR EACH ROW
EXECUTE PROCEDURE is_new_hotel_ok();

------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------

CREATE OR REPLACE FUNCTION hotel_update_ok() RETURNS TRIGGER AS $$
DECLARE
  ownerallreadyintown BOOLEAN;
  onlyownerchanged BOOLEAN;
BEGIN
  onlyownerchanged :=(
    OLD.locationcountry = NEW.locationcountry
    AND OLD.locationname = NEW.locationname
    AND OLD.name = NEW.name
  );
  IF(NOT onlyownerchanged) THEN
    RAISE EXCEPTION 'Only the owner of an hotel can be changed!';
  ELSE
    ownerallreadyintown :=(
      EXISTS(
          SELECT ownerpersonnummer
          FROM Hotels
          WHERE locationcountry = NEW.locationcountry
                AND locationname = NEW.locationname
                AND ownercountry = NEW.ownercountry
                AND ownerpersonnummer = NEW.ownerpersonnummer
      )
    );
    IF(NOT ownerallreadyintown ) THEN
      RETURN NEW;
    ELSE
      RAISE EXCEPTION 'That person already has an hotel in that city';
    END IF;
  END IF;
END;
$$ LANGUAGE 'plpgsql';


DROP TRIGGER IF EXISTS hotel_update ON Hotels;

CREATE TRIGGER hotel_update BEFORE UPDATE ON Hotels
FOR EACH ROW
EXECUTE PROCEDURE hotel_update_ok();

------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
----------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION hotel_sold() RETURNS TRIGGER AS $$
BEGIN
  UPDATE Persons SET budget = budget + (getval('hotelprice')*getval('hotelrefund'))
  WHERE OLD.ownercountry = country
    AND OLD.ownerpersonnummer = personnummer;
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';


DROP TRIGGER IF EXISTS hotel_delete ON Hotels;

CREATE TRIGGER hotel_delete AFTER DELETE ON Hotels
FOR EACH ROW
EXECUTE PROCEDURE hotel_sold();

--INSERT/UPDATE Hotels When a hotel is created, the price of the hotel must be deducted from that Person�s budget.
--Hotels can not be moved to a new city, but they can change owner. Keep in mind that a Person can only own one Hotel
---per City. Persons can sell their hotel, in which case the hotel is deleted from the Hotels table. When that happens,
--the Person get refunded with a fraction (getval(�hotelrefund�)) of the price of the hotel (getval(�hotelprice�)).

--END Hotels
----------------------------------------------------------------------------------
