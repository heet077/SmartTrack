-- Insert instructors from the timetable
INSERT INTO instructors (name, email, username, short_name, password)
VALUES 
    ('SS', 'ss@daiict.ac.in', 'ss@daiict.ac.in', 'SS', 'password123'),
    ('RC', 'rc@daiict.ac.in', 'rc@daiict.ac.in', 'RC', 'password123'),
    ('RLD', 'rld@daiict.ac.in', 'rld@daiict.ac.in', 'RLD', 'password123'),
    ('PK', 'pk@daiict.ac.in', 'pk@daiict.ac.in', 'PK', 'password123'),
    ('AM', 'am@daiict.ac.in', 'am@daiict.ac.in', 'AM', 'password123'),
    ('AM2', 'am2@daiict.ac.in', 'am2@daiict.ac.in', 'AM2', 'password123'),
    ('NJ', 'nj@daiict.ac.in', 'nj@daiict.ac.in', 'NJ', 'password123'),
    ('VS', 'vs@daiict.ac.in', 'vs@daiict.ac.in', 'VS', 'password123'),
    ('SB2', 'sb2@daiict.ac.in', 'sb2@daiict.ac.in', 'SB2', 'password123'),
    ('AR', 'ar@daiict.ac.in', 'ar@daiict.ac.in', 'AR', 'password123'),
    ('PK2', 'pk2@daiict.ac.in', 'pk2@daiict.ac.in', 'PK2', 'password123'),
    ('AKR', 'akr@daiict.ac.in', 'akr@daiict.ac.in', 'AKR', 'password123'),
    ('SR', 'sr@daiict.ac.in', 'sr@daiict.ac.in', 'SR', 'password123')
ON CONFLICT (email) DO UPDATE 
SET 
    name = EXCLUDED.name,
    username = EXCLUDED.username,
    short_name = EXCLUDED.short_name; 