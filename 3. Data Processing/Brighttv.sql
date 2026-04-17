SELECT 
    COALESCE(A.UserID, B.UserID) AS UserID,

    -- 2. Handle NULLs
    COALESCE(B.Gender, 'Unknown') AS Gender,
    COALESCE(B.Race, 'Unknown') AS Race,
    COALESCE(B.Province, 'Unknown') AS Province,
    IFNULL (B.Age,0) AS Age,
    IFNULL (B.GENDER,'No_Gender') AS Gender,
    IFNULL (B.Race, 'No_Race') AS Race,
    IFNULL (B.Province, 'No_province') AS Province,
    IFNULL (A.Channel2,'No_Channel') AS Channel2, 
    IFNULL (A.RecordDate2,'No_Date') AS RecordDate2,

    -- 3. Age Buckets
    CASE 
        WHEN B.Age IS NULL THEN '0'
        WHEN B.Age < 18 THEN '<18'
        WHEN B.Age BETWEEN 18 AND 24 THEN '18-24'
        WHEN B.Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN B.Age BETWEEN 35 AND 44 THEN '35-44'
        ELSE '45+'
    END AS Age_Group,

    -- 4. Clean Channel
    UPPER(TRIM(A.Channel2)) AS Channel,

    -- 5. Convert UTC → SA Time
    FROM_UTC_TIMESTAMP(TO_TIMESTAMP(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg') AS SA_DateTime,

    -- Extract Date & Hour (useful for analysis)
    DATE(FROM_UTC_TIMESTAMP(TO_TIMESTAMP(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg')) AS SA_Date,
    HOUR(FROM_UTC_TIMESTAMP(TO_TIMESTAMP(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg')) AS SA_Hour,

    -- 6. Join Check
    CASE 
        WHEN A.UserID IS NULL THEN 'Only Profile Data'
        WHEN B.UserID IS NULL THEN 'Only Viewership Data'
        ELSE 'Matched'
    END AS Join_Status,
    
    -- 7. Age Bucket
    CASE 
        WHEN B.Age IS NULL THEN 'No_age'
        WHEN B.Age <= 13 THEN 'Children'
        WHEN B.Age BETWEEN 14 AND 17 THEN 'Teen'
        WHEN B.Age BETWEEN 18 AND 29 THEN 'Young Adult'
        WHEN B.Age BETWEEN 30 AND 50 THEN 'Adult'
        WHEN B.Age BETWEEN 51 AND 65 THEN 'Middle Age'
        ELSE 'Senior'
    END AS Age_Bucket,
    
    -- 8. Time Bucket
    CASE 
        WHEN date_format(FROM_UTC_TIMESTAMP(TO_TIMESTAMP(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg'), 'HH:mm:ss') BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning Viewing'
        WHEN date_format(FROM_UTC_TIMESTAMP(TO_TIMESTAMP(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg'), 'HH:mm:ss') BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon Viewing'
        WHEN date_format(FROM_UTC_TIMESTAMP(TO_TIMESTAMP(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg'), 'HH:mm:ss') BETWEEN '18:00:00' AND '22:59:59' THEN 'Evening Viewing'
        ELSE 'Midnight Viewing'
    END AS Time_Bucket,

    ----9. Day of the week 
CASE 
    WHEN A.RecordDate2 IS NULL THEN 'Unknown'
    ELSE date_format(
        FROM_UTC_TIMESTAMP(TO_TIMESTAMP(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg'),
        'EEEE'
    )
END AS Day_of_Week,

---10 Date Type
CASE 
    WHEN A.RecordDate2 IS NULL THEN 'Unknown'
    WHEN date_format(
        FROM_UTC_TIMESTAMP(TO_TIMESTAMP(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg'),
        'E'
    ) IN ('Sat', 'Sun') THEN 'Weekend'
    ELSE 'Weekday'
END AS Day_Type

FROM bright_tv_analysis.default.bright_tv_viewership AS A
FULL OUTER JOIN bright_tv_analysis.default.bright_tv_user_profiles AS B
ON A.UserID = B.UserID;