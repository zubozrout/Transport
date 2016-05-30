function dbInit(tx) {
    tx.executeSql("CREATE TABLE IF NOT EXISTS stops(ID INTEGER PRIMARY KEY AUTOINCREMENT, key TEXT, value TEXT, coorX REAL, coorY REAL)");
    tx.executeSql("CREATE TABLE IF NOT EXISTS type(id TEXT UNIQUE, name TEXT, nameExt TEXT, title TEXT, city TEXT, description TEXT, homeState TEXT, trTypes TEXT, ttValidFrom TEXT, ttValidTo TEXT)");
    tx.executeSql("CREATE TABLE IF NOT EXISTS settings(key TEXT UNIQUE, value TEXT)");
    tx.executeSql("CREATE TABLE IF NOT EXISTS recent(ID INTEGER PRIMARY KEY AUTOINCREMENT, date DATETIME DEFAULT CURRENT_TIMESTAMP, typeid TEXT, stopidfrom INTEGER, stopidto INTEGER, stopidvia INTEGER, CONSTRAINT unq UNIQUE (typeid, stopidfrom, stopidto, stopidvia))")
}

function loadDB() {
    if(db == null) {
        try {
            db = LocalStorage.openDatabaseSync("transport-cz", "", "Simple Transport App for searching connections", 1000000, function(db) {
                db.transaction(function(tx){
                    dbInit(tx);
                });
            });

            if(db.version != "0.8") {
                db.changeVersion(db.version, "0.8");
                db.transaction(function(tx){
                    tx.executeSql("DROP TABLE settings");
                    tx.executeSql("DROP TABLE type");
                    tx.executeSql("DROP TABLE stops");
                    tx.executeSql("DROP TABLE recent");
                    dbInit(tx);
                });
            }
            else {
                db.transaction(function(tx){
                    dbInit(tx);
                });
            }
        } catch(err) {
            console.log("Error opening database: " + err);
        };
    }
}

function clearLocalStorage() {
    loadDB();
    try {
        db.transaction(function(tx){
            tx.executeSql("DELETE from settings");
            tx.executeSql("DELETE from type");
            tx.executeSql("DELETE from stops");
            tx.executeSql("DELETE from recent");
        });
    } catch(err) {
        console.log("Error deleting user data: " + err);
    };
}

// Save value with a unique key in the DB
function saveSetting(key, value) {
    if(typeof value !== typeof undefined) {
        loadDB();
        if(value == true) {
            value = "true";
        }
        else if(value == false) {
            value = "false";
        }
        try {
            db.transaction(function(tx) {
                var linesAffected = tx.executeSql("INSERT OR REPLACE INTO settings VALUES(?, ?)", [key, value]);
                if(linesAffected.rowsAffected != 1) {
                    console.log("An error occured while saving [" + key + "] " + value);
                }
            });
        } catch(err) {
            console.log("Error inserting data to the database: " + err);
        };
    }
}

// Get a saved value based upon a passed key from DB
// Returns a setting value
function getSetting(key) {
    loadDB();
    var res = null;
    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT * FROM settings WHERE key=?", [key]);
            if(typeof rs.rows.item(0) !== typeof undefined) {
                res = rs.rows.item(0).value != "" ? rs.rows.item(0).value : null;
                if(res == "true") {
                    res = true;
                }
                else if(res == "false") {
                    res = false;
                }
            }
            else {
                res = null;
            }
        });
    } catch(err) {
        console.log("Unable to read from the database: " + err);
    };
    return res;
}

// Create or replace a new transport type where type is a unique transport type ID
// Takes {type:"", name:"", nameExt:"", title:"", city:"", description:"", homeState:"", trTypes:"", ttValidFrom:"", ttValidTo:""}
function appendNewType(dataObj) {
    if(dataObj.type && Object.keys(dataObj).length == 10) {
        loadDB();
        db.transaction(function(tx) {
            var linesAffected = tx.executeSql("INSERT OR REPLACE INTO type VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [
                dataObj.type,
                dataObj.name,
                dataObj.nameExt,
                dataObj.title,
                dataObj.city,
                dataObj.description,
                dataObj.homeState,
                dataObj.trTypes,
                dataObj.ttValidFrom,
                dataObj.ttValidTo
            ]);
            if(linesAffected.rowsAffected != 1) {
                console.log("An error occured while inserting or updating transport type [" + dataObj.type + "] " + dataObj.name + "(" + dataObj.city + ", " + dataObj.description + ", " + dataObj.trTypes + ", " + dataObj.ttValidFrom + ", " + dataObj.ttValidTo + ")");
            }
        });
    }
}

// Check whether transport type exists
// Returns bool
function hasType(type) {
    loadDB();
    var exists = false;
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT Count(*) as count FROM type WHERE id=?", [type]);
        if(rs.rows.item(0).count > 0) {
            exists = true;
        }
    });
    return exists;
}

// Get all saved transport types
// Returns a two dimensional array of transport type ids with all their defined parameters
function getAllTypes() {
    loadDB();
    var res = [];
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT * FROM type ORDER BY city, homeState");
        for(var i = 0; i < rs.rows.length; i++) {
            res[i] = {};
            if(typeof rs.rows.item(i) !== typeof undefined) {
                if(rs.rows.item(i).value != "") {
                    res[i] = rs.rows.item(i);
                    for(var key in res[i]) {
                        try {
                            res[i][key] = JSON.parse(res[i][key]);
                        }
                        catch(e) {
                        }
                    }
                }
            }
        }
    });
    return res;
}

// Get list of all used transport type ids
// Returns an array of transport type ids
function getAllUsedTypes() {
    loadDB();
    var res = [];
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT DISTINCT type.id FROM type INNER JOIN stops ON type.id = stops.key");
        for(var i = 0; i < rs.rows.length; i++) {
            if(typeof rs.rows.item(i) !== typeof undefined) {
                res.push(rs.rows.item(i).id);
            }
        }
    });
    return res;
}

// Delete transport type with a defined id
function deleteType(type) {
    loadDB();
    if(hasType(type)) {
        db.transaction(function(tx) {
            var linesAffected = tx.executeSql("DELETE FROM type WHERE id=?", [type]);
            if(linesAffected.rowsAffected != 1) {
                console.log("An error occured while deleting transport type " + type);
            }
        });
    }
}

// Iserts or updates stops for defined type to the DB
function appendNewStop(type, name, coor) {
    if(name) {
        loadDB();
        db.transaction(function(tx) {
            var lines = tx.executeSql("SELECT rowid as id FROM stops WHERE key=? AND value=?", [type, name]);
            var id = null;
            var linesAffected = 0;
            if(lines.rows.length > 0) {
                id = lines.rows.item(0).id;
                linesAffected = tx.executeSql("INSERT OR REPLACE INTO stops VALUES(?, ?, ?, ?, ?)", [id, type, name, coor.x, coor.y]);

                if(lines.rows.length > 1) {
                    console.log("Attention! The dababase has " + lines.rows.length + " stop duplicates: [" + type + "] " + name);
                    console.log("Please report this bug and clear application cache to start from scratch.");
                }
            }
            else {
                linesAffected = tx.executeSql("INSERT OR REPLACE INTO stops VALUES(null, ?, ?, ?, ?)", [type, name, coor.x, coor.y]);
            }

            if(linesAffected.rowsAffected != 1) {
                console.log("An error occured while inserting or updating stop [" + type + "] " + name);
            }
        });
    }
}

// Check whether a stop with its name is serviced by the defined transport type
// Returns bool
function hasStop(type, name) {
    loadDB();
    var exists = false;
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT Count(*) as count FROM stops WHERE key=? AND value=?", [type, name]);
        if(rs.rows.item(0).count > 0) {
            exists = true;
        }
    });
    return exists;
}

// Check whtether there are any stops saved for the passed transport type
// Returns bool
function hasTransportStop(type) {
    loadDB();
    var exists = false;
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT Count(*) as count FROM stops WHERE key=?", [type]);
        if(rs.rows.item(0).count > 0) {
            exists = true;
        }
    });
    return exists;
}

// Get all stops from the DB for the defined type containing the passed string
// Returns an array of objects with station names and their coordinates
function getRelevantStops(type, containing) {
    loadDB();
    var res = [];
    db.transaction(function(tx) {
        /*
        var rs = tx.executeSql("SELECT value FROM stops WHERE key=? AND value LIKE ? ORDER BY value ASC LIMIT 10", [type, '%' + containing + '%']);
        for(var i = 0; i < rs.rows.length; i++) {
            if(typeof rs.rows.item(i) !== typeof undefined && rs.rows.item(i).value) {
                res.push(rs.rows.item(i).value);
            }
        }
        */
        var rs = tx.executeSql("SELECT ID,value,coorX,coorY FROM stops WHERE key=? ORDER BY value ASC", [type]);
        for(var i = 0; i < rs.rows.length; i++) {
            if(typeof rs.rows.item(i) !== typeof undefined && rs.rows.item(i).value) {
                if(res.length <= 10 && latiniseString(rs.rows.item(i).value).toLowerCase().indexOf(latiniseString(containing).toLowerCase()) > -1) {
                    res.push({"id": rs.rows.item(i).ID, "name": rs.rows.item(i).value, "coorX": rs.rows.item(i).coorX, "coorY": rs.rows.item(i).coorY});
                }
            }
        }
    });
    return res;
}

// Get all stops from the DB for the defined type close to the current location
// Returns an array of objects with station names and their latitude and longitude coordinations
function getNearbyStops(type, coor) {
    if(type) {
        loadDB();
        var res = [];
        db.transaction(function(tx) {
            var fudge = Math.pow(Math.cos((coor.x) * Math.PI / 180),2);
            var rs = tx.executeSql("SELECT value,coorX,coorY FROM stops WHERE key=? AND coorX IS NOT NULL AND coorY IS NOT NULL ORDER BY ((? - coorX) * (? - coorX) + (? - coorY) * (? - coorY) * ?) ASC LIMIT 5", [type, coor.x, coor.x, coor.y, coor.y, fudge]);
            for(var i = 0; i < rs.rows.length; i++) {
                if(Engine.latLongDistance(coor.x, coor.y, rs.rows.item(i).coorX, rs.rows.item(i).coorY) > 1) {
                    break;
                }
                res.push({"name": rs.rows.item(i).value, "coorX": rs.rows.item(i).coorX, "coorY": rs.rows.item(i).coorY});
            }
        });
        return res;
    }
    return [];
}

// Get all stops existing in the DB
// Returns a station objects containing key and value in an alphabetically ordered array
function getAllStops() {
    loadDB();
    var res = [];
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT key,value,coorX,coorY FROM stops ORDER BY value ASC");
        for(var i = 0; i < rs.rows.length; i++) {
            if(typeof rs.rows.item(i) !== typeof undefined && rs.rows.item(i).value) {
                res.push({"key": rs.rows.item(i).key, "value": rs.rows.item(i).value, "coorX": rs.rows.item(i).coorX, "coorY": rs.rows.item(i).coorY});
            }
        }
    });
    return res;
}

// Get stop by trasprort type id and name
// Returns a station object
function getStopByName(comb) {
    var res = null;
    if(comb && comb.name) {
        loadDB();
        db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT * FROM stops WHERE key=? AND value=?", [comb.id, comb.name]);
            if(rs.rows.length > 0) {
                res = ({"id": rs.rows.item(0).ID, "key": rs.rows.item(0).key, "value": rs.rows.item(0).value, "coorX": rs.rows.item(0).coorX, "coorY": rs.rows.item(0).coorY});
            }
        });
    }
    return res;
}

// Get stop by stop id
// Returns a station object
function getStopByID(id) {
    var res = null;
    if(id) {
        loadDB();
        db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT * FROM stops WHERE ID=?", id);
            for(var i = 0; i < rs.rows.length; i++) {
                res = ({"key": rs.rows.item(i).key, "value": rs.rows.item(i).value, "coorX": rs.rows.item(i).coorX, "coorY": rs.rows.item(i).coorY});
            }
        });
    }
    return res;
}

// Delete station from DB based upon its transport type and name
function deleteStop(type, name) {
    loadDB();
    if(!hasType(type)) {
        db.transaction(function(tx) {
            var linesAffected = tx.executeSql("DELETE FROM stops WHERE ?=?", [type, name]);
            if(linesAffected.rowsAffected != 1) {
                console.log("An error occured while deleting stop [" + type + "] " + name);
            }
        });
    }
}

// Delete all stops for the defined tranport type
function deleteAllTransportStops(type) {
    loadDB();
    db.transaction(function(tx) {
        var linesAffected = tx.executeSql("DELETE FROM stops WHERE key=?", [type]);
        if(linesAffected.rowsAffected <= 0) {
            console.log("An error occured while deleting all stops for: " + type + " transport");
        }
        else {
            saveSetting("from" + type, "");
            saveSetting("to" + type, "");
            saveSetting("via" + type, "");
        }
    });
}

// Append new search to history
function appendSearchToHistory(search) {
    var success = false;
    if(search) {
        loadDB();
        db.transaction(function(tx) {
            var countOfLines = tx.executeSql("SELECT Count(*) as count FROM recent").rows.item(0).count;
            var linesAffected = 0;
            var limit = 40;
            if(countOfLines < limit) {
                if(!search.stopidfrom || !search.stopidto) {
                    console.log("Can't save history entry without initial and final station.");
                    success = false;
                    return false;
                }
                if(!search.stopidvia) {
                    search.stopidvia = -1;
                }
                var matchedLines = tx.executeSql("SELECT Count(*) as count FROM recent WHERE typeid=? AND stopidfrom=? AND stopidto=? AND stopidvia=?", [search.typeid, search.stopidfrom, search.stopidto, search.stopidvia]);
                if(matchedLines.rows.item(0).count <= 0) {
                    linesAffected = tx.executeSql("INSERT OR REPLACE INTO recent(typeid, stopidfrom, stopidto, stopidvia) VALUES(?, ?, ?, ?)", [search.typeid, search.stopidfrom, search.stopidto, search.stopidvia]);
                }
                else {
                    var dbFix = tx.executeSql("SELECT * FROM recent");
                    var fixed = false;
                    for(var i = 0; i < dbFix.rows.length; i++) {
                        if(!dbFix.rows.item(i).stopidfrom || !dbFix.rows.item(i).stopidto) {
                            if(dbFix.rows.item(i).ID) {
                                deleteSearchHistory(dbFix.rows.item(i).ID);
                                fixed = true;
                            }
                            else {
                                deleteAllSearchHistory();
                                fixed = true;
                                console.log("Search histroy deleted due to a DB error");
                            }
                        }
                    }
                    if(fixed) {
                        return appendSearchToHistory(search);
                    }

                    linesAffected = tx.executeSql("INSERT OR REPLACE INTO recent(ID, typeid, stopidfrom, stopidto, stopidvia) VALUES(?, ?, ?, ?, ?)", [matchedLines.rows.item(0).id, search.typeid, search.stopidfrom, search.stopidto, search.stopidvia]);
                }
            }
            else {
                linesAffected = tx.executeSql("DELETE FROM recent WHERE ID IN (SELECT ID FROM recent ORDER BY ID LIMIT ?)", [(countOfLines - limit)]);
                success = appendSearchToHistory(search);
                return false;
            }

            if(linesAffected.rowsAffected != 1) {
                console.log("An error occured while creating or updating search history.");
                success = false;
            }
        });
    }
    return success;
}

// Delete all search history by ID
function deleteAllSearchHistory() {
    loadDB();
    db.transaction(function(tx) {
        var linesAffected = tx.executeSql("DELETE FROM recent");
        if(linesAffected.rowsAffected != 1) {
            console.log("Nothing was deleted in the search history.");
        }
    });
}

// Delete search history by ID
function deleteSearchHistory(id) {
    loadDB();
    db.transaction(function(tx) {
        var linesAffected = tx.executeSql("DELETE FROM recent WHERE ID=?", [id]);
        if(linesAffected.rowsAffected != 1) {
            console.log("Nothing was deleted in the search history.");
        }
    });
}

// Get a list of recent search history
// Returns ID, typeid, date, typename and names: stopfrom, stopto and stopvia + coordinates like stopfromx and stopfromy
function getSearchHistory() {
    loadDB();
    var searches = [];
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT recent.ID as ID, recent.typeid AS typeid, datetime(recent.date, 'localtime') AS date, trtype.name as typename, stopsfrom.value AS stopfrom, stopsfrom.coorX AS stopfromx, stopsfrom.coorY AS stopfromy, stopsto.value AS stopto, stopsto.coorX AS stoptox, stopsto.coorY AS stoptoy, stopsvia.value AS stopvia, stopsvia.coorX AS stopviax, stopsvia.coorY AS stopviay FROM recent INNER JOIN type trtype ON (trtype.id = recent.typeid) INNER JOIN stops stopsfrom ON (recent.stopidfrom = stopsfrom.ID) INNER JOIN stops stopsto ON (recent.stopidto = stopsto.ID) LEFT JOIN stops stopsvia ON (recent.stopidvia = stopsvia.ID) ORDER BY date DESC");
        for(var i = 0; i < rs.rows.length; i++) {
            searches.push(rs.rows.item(i));
        }
    });
    return searches;
}

// Transform strings containing national characters to ASCII
// Returns a processed string
function latiniseString(string) {
    var Latinise = {};
    Latinise.latin_map = {"Á":"A","Ă":"A","Ắ":"A","Ặ":"A","Ằ":"A","Ẳ":"A","Ẵ":"A","Ǎ":"A","Â":"A","Ấ":"A","Ậ":"A","Ầ":"A","Ẩ":"A","Ẫ":"A","Ä":"A","Ǟ":"A","Ȧ":"A","Ǡ":"A","Ạ":"A","Ȁ":"A","À":"A","Ả":"A","Ȃ":"A","Ā":"A","Ą":"A","Å":"A","Ǻ":"A","Ḁ":"A","Ⱥ":"A","Ã":"A","Ꜳ":"AA","Æ":"AE","Ǽ":"AE","Ǣ":"AE","Ꜵ":"AO","Ꜷ":"AU","Ꜹ":"AV","Ꜻ":"AV","Ꜽ":"AY","Ḃ":"B","Ḅ":"B","Ɓ":"B","Ḇ":"B","Ƀ":"B","Ƃ":"B","Ć":"C","Č":"C","Ç":"C","Ḉ":"C","Ĉ":"C","Ċ":"C","Ƈ":"C","Ȼ":"C","Ď":"D","Ḑ":"D","Ḓ":"D","Ḋ":"D","Ḍ":"D","Ɗ":"D","Ḏ":"D","ǲ":"D","ǅ":"D","Đ":"D","Ƌ":"D","Ǳ":"DZ","Ǆ":"DZ","É":"E","Ĕ":"E","Ě":"E","Ȩ":"E","Ḝ":"E","Ê":"E","Ế":"E","Ệ":"E","Ề":"E","Ể":"E","Ễ":"E","Ḙ":"E","Ë":"E","Ė":"E","Ẹ":"E","Ȅ":"E","È":"E","Ẻ":"E","Ȇ":"E","Ē":"E","Ḗ":"E","Ḕ":"E","Ę":"E","Ɇ":"E","Ẽ":"E","Ḛ":"E","Ꝫ":"ET","Ḟ":"F","Ƒ":"F","Ǵ":"G","Ğ":"G","Ǧ":"G","Ģ":"G","Ĝ":"G","Ġ":"G","Ɠ":"G","Ḡ":"G","Ǥ":"G","Ḫ":"H","Ȟ":"H","Ḩ":"H","Ĥ":"H","Ⱨ":"H","Ḧ":"H","Ḣ":"H","Ḥ":"H","Ħ":"H","Í":"I","Ĭ":"I","Ǐ":"I","Î":"I","Ï":"I","Ḯ":"I","İ":"I","Ị":"I","Ȉ":"I","Ì":"I","Ỉ":"I","Ȋ":"I","Ī":"I","Į":"I","Ɨ":"I","Ĩ":"I","Ḭ":"I","Ꝺ":"D","Ꝼ":"F","Ᵹ":"G","Ꞃ":"R","Ꞅ":"S","Ꞇ":"T","Ꝭ":"IS","Ĵ":"J","Ɉ":"J","Ḱ":"K","Ǩ":"K","Ķ":"K","Ⱪ":"K","Ꝃ":"K","Ḳ":"K","Ƙ":"K","Ḵ":"K","Ꝁ":"K","Ꝅ":"K","Ĺ":"L","Ƚ":"L","Ľ":"L","Ļ":"L","Ḽ":"L","Ḷ":"L","Ḹ":"L","Ⱡ":"L","Ꝉ":"L","Ḻ":"L","Ŀ":"L","Ɫ":"L","ǈ":"L","Ł":"L","Ǉ":"LJ","Ḿ":"M","Ṁ":"M","Ṃ":"M","Ɱ":"M","Ń":"N","Ň":"N","Ņ":"N","Ṋ":"N","Ṅ":"N","Ṇ":"N","Ǹ":"N","Ɲ":"N","Ṉ":"N","Ƞ":"N","ǋ":"N","Ñ":"N","Ǌ":"NJ","Ó":"O","Ŏ":"O","Ǒ":"O","Ô":"O","Ố":"O","Ộ":"O","Ồ":"O","Ổ":"O","Ỗ":"O","Ö":"O","Ȫ":"O","Ȯ":"O","Ȱ":"O","Ọ":"O","Ő":"O","Ȍ":"O","Ò":"O","Ỏ":"O","Ơ":"O","Ớ":"O","Ợ":"O","Ờ":"O","Ở":"O","Ỡ":"O","Ȏ":"O","Ꝋ":"O","Ꝍ":"O","Ō":"O","Ṓ":"O","Ṑ":"O","Ɵ":"O","Ǫ":"O","Ǭ":"O","Ø":"O","Ǿ":"O","Õ":"O","Ṍ":"O","Ṏ":"O","Ȭ":"O","Ƣ":"OI","Ꝏ":"OO","Ɛ":"E","Ɔ":"O","Ȣ":"OU","Ṕ":"P","Ṗ":"P","Ꝓ":"P","Ƥ":"P","Ꝕ":"P","Ᵽ":"P","Ꝑ":"P","Ꝙ":"Q","Ꝗ":"Q","Ŕ":"R","Ř":"R","Ŗ":"R","Ṙ":"R","Ṛ":"R","Ṝ":"R","Ȑ":"R","Ȓ":"R","Ṟ":"R","Ɍ":"R","Ɽ":"R","Ꜿ":"C","Ǝ":"E","Ś":"S","Ṥ":"S","Š":"S","Ṧ":"S","Ş":"S","Ŝ":"S","Ș":"S","Ṡ":"S","Ṣ":"S","Ṩ":"S","Ť":"T","Ţ":"T","Ṱ":"T","Ț":"T","Ⱦ":"T","Ṫ":"T","Ṭ":"T","Ƭ":"T","Ṯ":"T","Ʈ":"T","Ŧ":"T","Ɐ":"A","Ꞁ":"L","Ɯ":"M","Ʌ":"V","Ꜩ":"TZ","Ú":"U","Ŭ":"U","Ǔ":"U","Û":"U","Ṷ":"U","Ü":"U","Ǘ":"U","Ǚ":"U","Ǜ":"U","Ǖ":"U","Ṳ":"U","Ụ":"U","Ű":"U","Ȕ":"U","Ù":"U","Ủ":"U","Ư":"U","Ứ":"U","Ự":"U","Ừ":"U","Ử":"U","Ữ":"U","Ȗ":"U","Ū":"U","Ṻ":"U","Ų":"U","Ů":"U","Ũ":"U","Ṹ":"U","Ṵ":"U","Ꝟ":"V","Ṿ":"V","Ʋ":"V","Ṽ":"V","Ꝡ":"VY","Ẃ":"W","Ŵ":"W","Ẅ":"W","Ẇ":"W","Ẉ":"W","Ẁ":"W","Ⱳ":"W","Ẍ":"X","Ẋ":"X","Ý":"Y","Ŷ":"Y","Ÿ":"Y","Ẏ":"Y","Ỵ":"Y","Ỳ":"Y","Ƴ":"Y","Ỷ":"Y","Ỿ":"Y","Ȳ":"Y","Ɏ":"Y","Ỹ":"Y","Ź":"Z","Ž":"Z","Ẑ":"Z","Ⱬ":"Z","Ż":"Z","Ẓ":"Z","Ȥ":"Z","Ẕ":"Z","Ƶ":"Z","Ĳ":"IJ","Œ":"OE","ᴀ":"A","ᴁ":"AE","ʙ":"B","ᴃ":"B","ᴄ":"C","ᴅ":"D","ᴇ":"E","ꜰ":"F","ɢ":"G","ʛ":"G","ʜ":"H","ɪ":"I","ʁ":"R","ᴊ":"J","ᴋ":"K","ʟ":"L","ᴌ":"L","ᴍ":"M","ɴ":"N","ᴏ":"O","ɶ":"OE","ᴐ":"O","ᴕ":"OU","ᴘ":"P","ʀ":"R","ᴎ":"N","ᴙ":"R","ꜱ":"S","ᴛ":"T","ⱻ":"E","ᴚ":"R","ᴜ":"U","ᴠ":"V","ᴡ":"W","ʏ":"Y","ᴢ":"Z","á":"a","ă":"a","ắ":"a","ặ":"a","ằ":"a","ẳ":"a","ẵ":"a","ǎ":"a","â":"a","ấ":"a","ậ":"a","ầ":"a","ẩ":"a","ẫ":"a","ä":"a","ǟ":"a","ȧ":"a","ǡ":"a","ạ":"a","ȁ":"a","à":"a","ả":"a","ȃ":"a","ā":"a","ą":"a","ᶏ":"a","ẚ":"a","å":"a","ǻ":"a","ḁ":"a","ⱥ":"a","ã":"a","ꜳ":"aa","æ":"ae","ǽ":"ae","ǣ":"ae","ꜵ":"ao","ꜷ":"au","ꜹ":"av","ꜻ":"av","ꜽ":"ay","ḃ":"b","ḅ":"b","ɓ":"b","ḇ":"b","ᵬ":"b","ᶀ":"b","ƀ":"b","ƃ":"b","ɵ":"o","ć":"c","č":"c","ç":"c","ḉ":"c","ĉ":"c","ɕ":"c","ċ":"c","ƈ":"c","ȼ":"c","ď":"d","ḑ":"d","ḓ":"d","ȡ":"d","ḋ":"d","ḍ":"d","ɗ":"d","ᶑ":"d","ḏ":"d","ᵭ":"d","ᶁ":"d","đ":"d","ɖ":"d","ƌ":"d","ı":"i","ȷ":"j","ɟ":"j","ʄ":"j","ǳ":"dz","ǆ":"dz","é":"e","ĕ":"e","ě":"e","ȩ":"e","ḝ":"e","ê":"e","ế":"e","ệ":"e","ề":"e","ể":"e","ễ":"e","ḙ":"e","ë":"e","ė":"e","ẹ":"e","ȅ":"e","è":"e","ẻ":"e","ȇ":"e","ē":"e","ḗ":"e","ḕ":"e","ⱸ":"e","ę":"e","ᶒ":"e","ɇ":"e","ẽ":"e","ḛ":"e","ꝫ":"et","ḟ":"f","ƒ":"f","ᵮ":"f","ᶂ":"f","ǵ":"g","ğ":"g","ǧ":"g","ģ":"g","ĝ":"g","ġ":"g","ɠ":"g","ḡ":"g","ᶃ":"g","ǥ":"g","ḫ":"h","ȟ":"h","ḩ":"h","ĥ":"h","ⱨ":"h","ḧ":"h","ḣ":"h","ḥ":"h","ɦ":"h","ẖ":"h","ħ":"h","ƕ":"hv","í":"i","ĭ":"i","ǐ":"i","î":"i","ï":"i","ḯ":"i","ị":"i","ȉ":"i","ì":"i","ỉ":"i","ȋ":"i","ī":"i","į":"i","ᶖ":"i","ɨ":"i","ĩ":"i","ḭ":"i","ꝺ":"d","ꝼ":"f","ᵹ":"g","ꞃ":"r","ꞅ":"s","ꞇ":"t","ꝭ":"is","ǰ":"j","ĵ":"j","ʝ":"j","ɉ":"j","ḱ":"k","ǩ":"k","ķ":"k","ⱪ":"k","ꝃ":"k","ḳ":"k","ƙ":"k","ḵ":"k","ᶄ":"k","ꝁ":"k","ꝅ":"k","ĺ":"l","ƚ":"l","ɬ":"l","ľ":"l","ļ":"l","ḽ":"l","ȴ":"l","ḷ":"l","ḹ":"l","ⱡ":"l","ꝉ":"l","ḻ":"l","ŀ":"l","ɫ":"l","ᶅ":"l","ɭ":"l","ł":"l","ǉ":"lj","ſ":"s","ẜ":"s","ẛ":"s","ẝ":"s","ḿ":"m","ṁ":"m","ṃ":"m","ɱ":"m","ᵯ":"m","ᶆ":"m","ń":"n","ň":"n","ņ":"n","ṋ":"n","ȵ":"n","ṅ":"n","ṇ":"n","ǹ":"n","ɲ":"n","ṉ":"n","ƞ":"n","ᵰ":"n","ᶇ":"n","ɳ":"n","ñ":"n","ǌ":"nj","ó":"o","ŏ":"o","ǒ":"o","ô":"o","ố":"o","ộ":"o","ồ":"o","ổ":"o","ỗ":"o","ö":"o","ȫ":"o","ȯ":"o","ȱ":"o","ọ":"o","ő":"o","ȍ":"o","ò":"o","ỏ":"o","ơ":"o","ớ":"o","ợ":"o","ờ":"o","ở":"o","ỡ":"o","ȏ":"o","ꝋ":"o","ꝍ":"o","ⱺ":"o","ō":"o","ṓ":"o","ṑ":"o","ǫ":"o","ǭ":"o","ø":"o","ǿ":"o","õ":"o","ṍ":"o","ṏ":"o","ȭ":"o","ƣ":"oi","ꝏ":"oo","ɛ":"e","ᶓ":"e","ɔ":"o","ᶗ":"o","ȣ":"ou","ṕ":"p","ṗ":"p","ꝓ":"p","ƥ":"p","ᵱ":"p","ᶈ":"p","ꝕ":"p","ᵽ":"p","ꝑ":"p","ꝙ":"q","ʠ":"q","ɋ":"q","ꝗ":"q","ŕ":"r","ř":"r","ŗ":"r","ṙ":"r","ṛ":"r","ṝ":"r","ȑ":"r","ɾ":"r","ᵳ":"r","ȓ":"r","ṟ":"r","ɼ":"r","ᵲ":"r","ᶉ":"r","ɍ":"r","ɽ":"r","ↄ":"c","ꜿ":"c","ɘ":"e","ɿ":"r","ś":"s","ṥ":"s","š":"s","ṧ":"s","ş":"s","ŝ":"s","ș":"s","ṡ":"s","ṣ":"s","ṩ":"s","ʂ":"s","ᵴ":"s","ᶊ":"s","ȿ":"s","ɡ":"g","ᴑ":"o","ᴓ":"o","ᴝ":"u","ť":"t","ţ":"t","ṱ":"t","ț":"t","ȶ":"t","ẗ":"t","ⱦ":"t","ṫ":"t","ṭ":"t","ƭ":"t","ṯ":"t","ᵵ":"t","ƫ":"t","ʈ":"t","ŧ":"t","ᵺ":"th","ɐ":"a","ᴂ":"ae","ǝ":"e","ᵷ":"g","ɥ":"h","ʮ":"h","ʯ":"h","ᴉ":"i","ʞ":"k","ꞁ":"l","ɯ":"m","ɰ":"m","ᴔ":"oe","ɹ":"r","ɻ":"r","ɺ":"r","ⱹ":"r","ʇ":"t","ʌ":"v","ʍ":"w","ʎ":"y","ꜩ":"tz","ú":"u","ŭ":"u","ǔ":"u","û":"u","ṷ":"u","ü":"u","ǘ":"u","ǚ":"u","ǜ":"u","ǖ":"u","ṳ":"u","ụ":"u","ű":"u","ȕ":"u","ù":"u","ủ":"u","ư":"u","ứ":"u","ự":"u","ừ":"u","ử":"u","ữ":"u","ȗ":"u","ū":"u","ṻ":"u","ų":"u","ᶙ":"u","ů":"u","ũ":"u","ṹ":"u","ṵ":"u","ᵫ":"ue","ꝸ":"um","ⱴ":"v","ꝟ":"v","ṿ":"v","ʋ":"v","ᶌ":"v","ⱱ":"v","ṽ":"v","ꝡ":"vy","ẃ":"w","ŵ":"w","ẅ":"w","ẇ":"w","ẉ":"w","ẁ":"w","ⱳ":"w","ẘ":"w","ẍ":"x","ẋ":"x","ᶍ":"x","ý":"y","ŷ":"y","ÿ":"y","ẏ":"y","ỵ":"y","ỳ":"y","ƴ":"y","ỷ":"y","ỿ":"y","ȳ":"y","ẙ":"y","ɏ":"y","ỹ":"y","ź":"z","ž":"z","ẑ":"z","ʑ":"z","ⱬ":"z","ż":"z","ẓ":"z","ȥ":"z","ẕ":"z","ᵶ":"z","ᶎ":"z","ʐ":"z","ƶ":"z","ɀ":"z","ﬀ":"ff","ﬃ":"ffi","ﬄ":"ffl","ﬁ":"fi","ﬂ":"fl","ĳ":"ij","œ":"oe","ﬆ":"st","ₐ":"a","ₑ":"e","ᵢ":"i","ⱼ":"j","ₒ":"o","ᵣ":"r","ᵤ":"u","ᵥ":"v","ₓ":"x"};
    String.prototype.latinise = function() { return this.replace(/[^A-Za-z0-9\[\] ]/g, function(a) { return Latinise.latin_map[a]||a}) };
    String.prototype.latinize = String.prototype.latinise;
    String.prototype.isLatin = function() { return this == this.latinise() }

    return string ? string.latinize() : "";
}
