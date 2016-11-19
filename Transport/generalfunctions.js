"use strict";

function langCode(toInt) {
    var locale = Qt.locale().name;
    var lang = "";
    var num = 0;

    switch(locale.substring(0,2)) {
        case "en":
            lang = "ENGLISH";
            num = 1;
            break;
        case "de":
            lang = "GERMAN";
            num = 2;
            break;
        case "cs":
            lang = "CZECH";
            num = 0;
            break;
        case "sk":
            lang = "SLOVAK";
            num = 3;
            break;
        case "pl":
            lang = "POLISH";
            num = 4;
            break;
        default:
            lang = "ENGLISH";
            num = 1;
            break;
    }

    if(typeof toInt !== typeof undefined && toInt === true) {
        return num;
    }
    return lang;
}

function getTranpsortType(index) {
    switch(index) {
    case 1:
       return "train";
    case 2:
        return "bus";
    case 3:
        return "tram";
    case 4:
       return "trol";
    case 5:
       return "metro";
    case 6:
       return "ship";
    case 7:
       return "air";
    case 8:
       return "taxi";
    case 9:
       return "cableway";
    default:
       return "empty";
    }
}
