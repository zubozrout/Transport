![Transport Logo](https://github.com/zubozrout/Transport/blob/master/Transport/transport.png)
# Transport
Ubuntu Phone Transport Application v2 - Czech and Slovak public transport schedules + European trains + Airlines.

This is a Ubuntu Phone application for searching connections for public transport - mostly in the Czech and Slovak republic.
It uses API provided by CHAPS s.r.o. company.

Please note I can't share the private key used by this app - therefore using the code present in this repository will only allow you to use free API.
The real Ubuntu Phone app present in the store here https://open-store.io/app/transport.zubozrout contains the private key.

Here is the CHAPS API documentation: http://docs.crws.apiary.io/#reference

Please help translate this app here: https://www.transifex.com/zubozrout/transport/

# Building for Xenial
`clickable -k 16.04 --arch="armhf"`

# Prerequisites
You need to have this file in place (not part of this repository):

`Transport/backend/Transport/key.h`

containing the following line:

`QString KEY = "";`

(You can fill in the API key provided by CHAPS s.r.o. for extended functionality or leave the string empty as above)
