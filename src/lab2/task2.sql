
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
        FROM  Persons p, Roads r
        WHERE p.budget > r.roadtax
              AND p.locationarea = r.toarea
              AND p.locationcountry = r.tocountry)
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
        WHERE p.budget > r.roadtax
              AND p.locationarea = r.fromarea
              AND p.locationcountry = r.fromcountry)
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
            AND p.locationcountry = r.fromcountry)

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
            AND p.locationcountry = r.tocountry))AS huehue
    WHERE (country != ''
      AND personnummer != '')
      AND (country != ' '
      AND personnummer != ' ')
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
      (NEW.ownercountry = ' '
      AND NEW.ownerpersonnummer = ' ')
      OR
      (NEW.ownercountry = ''
      AND NEW.ownerpersonnummer = '')
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




--DELETE
--FROM Roads
--WHERE (fromcountry = 'Rus' OR fromcountry = 'Fin' )
--      AND (fromarea = 'San' OR fromarea = 'Hel')
--      AND (tocountry = 'Fin' OR tocountry = 'Rus' )
--      AND (toarea = 'Hel' OR toarea = 'San')
--      AND ownercountry = 'Swe'
--      AND ownerpersonnummer = '199607082667';



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
    AND roadtax >= 0
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
  governmentUpdate BOOLEAN;
  okUpdateData BOOLEAN;
  onlyBudgetOrName BOOLEAN;
  isLegalMove BOOLEAN;
  moveCost NUMERIC;
  newLocationCity BOOLEAN;
  visitBonusSum NUMERIC;
  cityHasHotels BOOLEAN;
  cityVisitSum NUMERIC;
  numOfHotels NUMERIC;
  travellerHasHotel BOOLEAN;
  travellerHotelProfit NUMERIC;
  newBudgetData NUMERIC;


BEGIN
--We are not allowed to update the keys OR budget (but everything else?)
  okUpdateData :=(
    NEW.country = OLD.country
    AND NEW.personnummer = OLD.personnummer
  );
  --Dont update the government!
  governmentUpdate :=(
                  (OLD.country = ' '
                  AND OLD.personnummer = ' ')
                OR
                  (OLD.country = ''
                  AND OLD.personnummer = '')
              );
  IF(governmentUpdate) THEN
    IF(okUpdateData) THEN
      RETURN NEW;
    ELSE
      RAISE EXCEPTION 'Dont change government origin!';
    END IF;
  END IF;
  --If its okay to continue
  IF(NOT okUpdateData) THEN
    RAISE EXCEPTION 'You are not allowed to update the country or personnummer of a person!';
  ELSE
    onlyBudgetOrName :=(
      OLD.locationcountry = NEW.locationcountry
      AND OLD.locationarea = NEW.locationarea
    );
    IF(onlyBudgetOrName)THEN
      RETURN NEW;
    END IF;
    --Can the person reach the NEW.location from its OLD.location? (The possible ones exist in NextMoves)
    isLegalMove :=(
      EXISTS(
          SELECT personnummer
          FROM NextMoves
          WHERE NEW.personnummer = personnummer
            AND NEW.country = personcountry
            AND NEW.locationcountry = destcountry
            AND NEW.locationarea = destarea
            AND OLD.locationcountry = country
            AND OLD.locationarea = area
      )
    );

    --If its okay
    IF(NOT isLegalMove) THEN
      RAISE EXCEPTION 'That person has no road connecting to that place!';
    ELSE
      --get the cost of that movement (should be fine if taken from NextMoves)
      moveCost :=(
        SELECT cost
        FROM NextMoves
        WHERE NEW.personnummer = personnummer
         AND NEW.country = personcountry
         AND NEW.locationcountry = destcountry
         AND NEW.locationarea = destarea
         AND OLD.locationcountry = country
         AND OLD.locationarea = area
      );

      --If we can afford to move
      IF(moveCost > NEW.budget) THEN
        RAISE EXCEPTION 'That person cant afford moving!';
      ELSE
        NEW.budget := (NEW.budget - moveCost);


        --Is NEW.location a city?
        newLocationCity := (
          EXISTS (
            SELECT name
            FROM Cities
            WHERE NEW.locationcountry = country
              AND NEW.locationarea = name )
        );

        --If it was then do this else just do update (return NEW?)
        IF(NOT newlocationCity) THEN
        UPDATE Persons SET budget = budget + moveCost
        FROM Roads
        WHERE personnummer = Roads.ownerpersonnummer
          AND country = Roads.ownercountry
          AND OLD.locationcountry = Roads.tocountry
          AND OLD.locationarea = Roads.toarea
          AND NEW.locationcountry = Roads.fromcountry
          AND NEW.locationarea = Roads.fromarea
          AND moveCost = Roads.roadtax
          AND (NEW.personnummer != Roads.ownerpersonnummer
          AND NEW.country != Roads.ownercountry);
        UPDATE Persons SET budget = budget + moveCost
        FROM Roads
        WHERE personnummer = Roads.ownerpersonnummer
          AND country = Roads.ownercountry
          AND NEW.locationcountry = Roads.tocountry
          AND NEW.locationarea = Roads.toarea
          AND OLD.locationcountry = Roads.fromcountry
          AND OLD.locationarea = Roads.fromarea
          AND moveCost = Roads.roadtax
          AND (NEW.personnummer != Roads.ownerpersonnummer
          AND NEW.country != Roads.ownercountry);

          UPDATE Persons SET locationarea = NEW.locationarea , locationcountry = NEW.locationcountry
          WHERE personnummer = NEW.personnummer
            AND country = NEW.country;
          --End with saying NEW is okay
          RETURN NEW;
        ELSE
          --get the visit bonus of city
          visitBonusSum :=(
            SELECT visitbonus
            FROM Cities
            WHERE NEW.locationcountry = country
              AND NEW.locationarea = name
          );

          --any hotels in the city?
          cityHasHotels :=(
            EXISTS (
                SELECT name
                FROM Hotels
                WHERE locationcountry = NEW.locationcountry
                      AND locationname = NEW.locationarea
            )
          );

          --Yes ^^
          IF(cityHasHotels) THEN
            --set cityVisit cost from constant & count hotels in town
            cityVisitSum :=( getval('cityvisit') );
            numOfHotels :=(
              SELECT COUNT(name)
              FROM Hotels
              WHERE locationcountry = NEW.locationcountry
                    AND locationname = NEW.locationarea
            );
          ELSE
            --No hotels = no cost, used in boolean expression
            numOfHotels :=(0);
            cityVisitSum :=(0);
          END IF;
          travellerHasHotel :=(
            EXISTS(
                SELECT name
                FROM Hotels
                WHERE NEW.personnummer = ownerpersonnummer
                      AND NEW.country = ownercountry
                      AND NEW.locationcountry = locationcountry
                      AND NEW.locationarea = locationname
            )
          );
          IF(travellerHasHotel) THEN
            travellerHotelProfit :=( cityVisitSum / numOfHotels );
          ELSE
            travellerHotelProfit :=( 0 );
          END IF;
          --Make sure budget wont go below 0, perhaps no changes should be done if this isnt a thing?
          IF( (OLD.budget + visitBonusSum + travellerHotelProfit) < (cityVisitSum + moveCost) ) THEN
            RAISE EXCEPTION 'That person cant afford staying in that city';
          ELSE
            NEW.budget = NEW.budget + visitBonusSum - cityVisitSum + travellerHotelProfit;
            --if there was a bonus set it to 0
            IF(visitBonusSum > 0) THEN
              UPDATE Cities SET visitbonus = 0
              WHERE NEW.locationcountry = country
                    AND NEW.locationarea = name;
            END IF;

            --update budget of hotel owners  CAN YOU DO THIS?!?!?!
            IF(numOfHotels > 0) THEN
              UPDATE Persons SET budget = budget + (cityVisitSum/numOfHotels)
              FROM Hotels h
              WHERE personnummer = h.ownerpersonnummer
                AND country = h.ownercountry
                AND NEW.locationcountry = h.locationcountry
                AND NEW.locationarea = h.locationname
                --These two following ANDs are to ensure we dont overwrite NEW data
                AND NEW.personnummer != h.ownerpersonnummer
                AND NEW.country != h.ownercountry;
            END IF;
            UPDATE Persons SET budget = budget + moveCost
            FROM Roads
            WHERE personnummer = Roads.ownerpersonnummer
              AND country = Roads.ownercountry
              AND OLD.locationcountry = Roads.tocountry
              AND OLD.locationarea = Roads.toarea
              AND NEW.locationcountry = Roads.fromcountry
              AND NEW.locationarea = Roads.fromarea
              AND moveCost = Roads.roadtax
              AND (NEW.personnummer != Roads.ownerpersonnummer
              AND NEW.country != Roads.ownercountry);
            UPDATE Persons SET budget = budget + moveCost
            FROM Roads
            WHERE personnummer = Roads.ownerpersonnummer
              AND country = Roads.ownercountry
              AND NEW.locationcountry = Roads.tocountry
              AND NEW.locationarea = Roads.toarea
              AND OLD.locationcountry = Roads.fromcountry
              AND OLD.locationarea = Roads.fromarea
              AND moveCost = Roads.roadtax
              AND (NEW.personnummer != Roads.ownerpersonnummer
              AND NEW.country != Roads.ownercountry);
            --update budget of traveler

            UPDATE Persons SET locationarea = NEW.locationarea , locationcountry = NEW.locationcountry
            WHERE personnummer = NEW.personnummer
              AND country = NEW.country;
            --End with saying NEW is okay
            RETURN NEW;
          END IF;
        END IF;
      END IF;
    END IF;
  END IF;
END
$$ LANGUAGE 'plpgsql';


DROP TRIGGER IF EXISTS person_update ON Persons;

CREATE TRIGGER person_update BEFORE UPDATE ON Persons
FOR EACH ROW
WHEN(
  (pg_trigger_depth()<2)
  AND (OLD.locationcountry != NEW.locationcountry
  OR OLD.locationarea != NEW.locationarea)
)
EXECUTE PROCEDURE update_person();

--END Person
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
