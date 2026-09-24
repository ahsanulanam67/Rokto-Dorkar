# Bangladesh location data

The application uses the current English names for Bangladesh's 8 divisions,
64 districts, and 500 upazilas as of September 2026.

Sources reviewed:

- [kamalahmed/list-of-places-in-bangladesh](https://github.com/kamalahmed/list-of-places-in-bangladesh) for the older division/district/upazila hierarchy (GPL-3.0, last updated in 2019).
- [Dhaka Tribune, 26 July 2021](https://www.dhakatribune.com/bangladesh/253338/three-new-upazilas-in-madaripur-cox%E2%80%99s-bazar-and) for Dasar, Eidgaon, Madhyanagar, and the renaming of Dakshin Sunamganj to Shantiganj.
- [The Business Standard, 7 May 2026](https://www.tbsnews.net/bangladesh/govt-approves-bogura-city-corporation-five-new-upazilas-1432741) for Mokamtola, Matamuhuri, Chandraganj, Ruhia, and Bhulli, which raised the official total from 495 to 500.

Police-station-only entries from older lists are not presented as upazilas. A
data migration normalizes legacy donor locations to current spellings without
deleting donor records.
