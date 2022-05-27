// SPDX-FileCopyrightText: © 2021-2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

contract Rates {

    mapping (uint256 => uint256) public rates;

    constructor() public {
        rates[    0] = 1000000000000000000000000000;
        rates[    1] = 1000000000003170820659990704;
        rates[    5] = 1000000000015850933588756013;
        rates[   10] = 1000000000031693947650284507;
        rates[   25] = 1000000000079175551708715274;
        rates[   50] = 1000000000158153903837946257;
        rates[   75] = 1000000000236936036262880196;
        rates[  100] = 1000000000315522921573372069;
        rates[  125] = 1000000000393915525145987602;
        rates[  150] = 1000000000472114805215157978;
        rates[  175] = 1000000000550121712943459312;
        rates[  200] = 1000000000627937192491029810;
        rates[  225] = 1000000000705562181084137268;
        rates[  250] = 1000000000782997609082909351;
        rates[  275] = 1000000000860244400048238898;
        rates[  300] = 1000000000937303470807876289;
        rates[  325] = 1000000001014175731521720677;
        rates[  350] = 1000000001090862085746321732;
        rates[  375] = 1000000001167363430498603315;
        rates[  400] = 1000000001243680656318820312;
        rates[  425] = 1000000001319814647332759691;
        rates[  450] = 1000000001395766281313196627;
        rates[  475] = 1000000001471536429740616381;
        rates[  500] = 1000000001547125957863212448;
        rates[  525] = 1000000001622535724756171269;
        rates[  550] = 1000000001697766583380253701;
        rates[  575] = 1000000001772819380639683201;
        rates[  600] = 1000000001847694957439350562;
        rates[  625] = 1000000001922394148741344865;
        rates[  650] = 1000000001996917783620820123;
        rates[  675] = 1000000002071266685321207000;
        rates[  700] = 1000000002145441671308778766;
        rates[  725] = 1000000002219443553326580536;
        rates[  750] = 1000000002293273137447730714;
        rates[  775] = 1000000002366931224128103346;
        rates[  800] = 1000000002440418608258400030;
        rates[  825] = 1000000002513736079215619839;
        rates[  850] = 1000000002586884420913935572;
        rates[  875] = 1000000002659864411854984565;
        rates[  900] = 1000000002732676825177582095;
        rates[  925] = 1000000002805322428706865331;
        rates[  950] = 1000000002877801985002875644;
        rates[  975] = 1000000002950116251408586949;
        rates[ 1000] = 1000000003022265980097387650;
        rates[ 1025] = 1000000003094251918120023627;
        rates[ 1050] = 1000000003166074807451009595;
        rates[ 1075] = 1000000003237735385034516037;
        rates[ 1100] = 1000000003309234382829738808;
        rates[ 1125] = 1000000003380572527855758393;
        rates[ 1150] = 1000000003451750542235895695;
        rates[ 1175] = 1000000003522769143241571114;
        rates[ 1200] = 1000000003593629043335673582;
        rates[ 1225] = 1000000003664330950215446102;
        rates[ 1250] = 1000000003734875566854894261;
        rates[ 1275] = 1000000003805263591546724039;
        rates[ 1300] = 1000000003875495717943815211;
        rates[ 1325] = 1000000003945572635100236468;
        rates[ 1350] = 1000000004015495027511808328;
        rates[ 1375] = 1000000004085263575156219812;
        rates[ 1400] = 1000000004154878953532704765;
        rates[ 1425] = 1000000004224341833701283597;
        rates[ 1450] = 1000000004293652882321576158;
        rates[ 1475] = 1000000004362812761691191350;
        rates[ 1500] = 1000000004431822129783699001;
        rates[ 1525] = 1000000004500681640286189459;
        rates[ 1550] = 1000000004569391942636426248;
        rates[ 1575] = 1000000004637953682059597074;
        rates[ 1600] = 1000000004706367499604668374;
        rates[ 1625] = 1000000004774634032180348552;
        rates[ 1650] = 1000000004842753912590664903;
        rates[ 1675] = 1000000004910727769570159235;
        rates[ 1700] = 1000000004978556227818707070;
        rates[ 1725] = 1000000005046239908035965222;
        rates[ 1750] = 1000000005113779426955452540;
        rates[ 1775] = 1000000005181175397378268462;
        rates[ 1800] = 1000000005248428428206454010;
        rates[ 1825] = 1000000005315539124475999751;
        rates[ 1850] = 1000000005382508087389505206;
        rates[ 1875] = 1000000005449335914348494113;
        rates[ 1900] = 1000000005516023198985389892;
        rates[ 1925] = 1000000005582570531195155575;
        rates[ 1950] = 1000000005648978497166602432;
        rates[ 1975] = 1000000005715247679413371444;
        rates[ 2000] = 1000000005781378656804591712;
        rates[ 2025] = 1000000005847372004595219844;
        rates[ 2050] = 1000000005913228294456064283;
        rates[ 2075] = 1000000005978948094503498507;
        rates[ 2100] = 1000000006044531969328866955;
        rates[ 2125] = 1000000006109980480027587488;
        rates[ 2150] = 1000000006175294184227954125;
        rates[ 2175] = 1000000006240473636119643770;
        rates[ 2200] = 1000000006305519386481930552;
        rates[ 2225] = 1000000006370431982711611382;
        rates[ 2250] = 1000000006435211968850646270;
        rates[ 2275] = 1000000006499859885613516871;
        rates[ 2300] = 1000000006564376270414306730;
        rates[ 2325] = 1000000006628761657393506584;
        rates[ 2350] = 1000000006693016577444548094;
        rates[ 2375] = 1000000006757141558240069277;
        rates[ 2400] = 1000000006821137124257914908;
        rates[ 2425] = 1000000006885003796806875073;
        rates[ 2450] = 1000000006948742094052165050;
        rates[ 2475] = 1000000007012352531040649627;
        rates[ 2500] = 1000000007075835619725814915;
        rates[ 2525] = 1000000007139191868992490695;
        rates[ 2550] = 1000000007202421784681326287;
        rates[ 2575] = 1000000007265525869613022867;
        rates[ 2600] = 1000000007328504623612325153;
        rates[ 2625] = 1000000007391358543531775311;
        rates[ 2650] = 1000000007454088123275231904;
        rates[ 2675] = 1000000007516693853821156670;
        rates[ 2700] = 1000000007579176223245671878;
        rates[ 2725] = 1000000007641535716745390957;
        rates[ 2750] = 1000000007703772816660025079;
        rates[ 2775] = 1000000007765888002494768329;
        rates[ 2800] = 1000000007827881750942464045;
        rates[ 2825] = 1000000007889754535905554913;
        rates[ 2850] = 1000000007951506828517819323;
        rates[ 2875] = 1000000008013139097165896490;
        rates[ 2900] = 1000000008074651807510602798;
        rates[ 2925] = 1000000008136045422508041783;
        rates[ 2950] = 1000000008197320402430510158;
        rates[ 2975] = 1000000008258477204887202245;
        rates[ 3000] = 1000000008319516284844715115;
        rates[ 3025] = 1000000008380438094647356774;
        rates[ 3050] = 1000000008441243084037259619;
        rates[ 3075] = 1000000008501931700174301437;
        rates[ 3100] = 1000000008562504387655836125;
        rates[ 3125] = 1000000008622961588536236324;
        rates[ 3150] = 1000000008683303742346250114;
        rates[ 3175] = 1000000008743531286112173869;
        rates[ 3200] = 1000000008803644654374843395;
        rates[ 3225] = 1000000008863644279208445392;
        rates[ 3250] = 1000000008923530590239151272;
        rates[ 3275] = 1000000008983304014663575373;
        rates[ 3300] = 1000000009042964977267059505;
        rates[ 3325] = 1000000009102513900441785827;
        rates[ 3350] = 1000000009161951204204719966;
        rates[ 3375] = 1000000009221277306215386279;
        rates[ 3400] = 1000000009280492621793477151;
        rates[ 3425] = 1000000009339597563936298181;
        rates[ 3450] = 1000000009398592543336051086;
        rates[ 3475] = 1000000009457477968396956129;
        rates[ 3500] = 1000000009516254245252215861;
        rates[ 3525] = 1000000009574921777780821942;
        rates[ 3550] = 1000000009633480967624206760;
        rates[ 3575] = 1000000009691932214202741592;
        rates[ 3600] = 1000000009750275914732082986;
        rates[ 3625] = 1000000009808512464239369028;
        rates[ 3650] = 1000000009866642255579267166;
        rates[ 3675] = 1000000009924665679449875210;
        rates[ 3700] = 1000000009982583124408477109;
        rates[ 3725] = 1000000010040394976887155106;
        rates[ 3750] = 1000000010098101621208259840;
        rates[ 3775] = 1000000010155703439599739931;
        rates[ 3800] = 1000000010213200812210332586;
        rates[ 3825] = 1000000010270594117124616733;
        rates[ 3850] = 1000000010327883730377930177;
        rates[ 3875] = 1000000010385070025971152244;
        rates[ 3900] = 1000000010442153375885353361;
        rates[ 3925] = 1000000010499134150096313024;
        rates[ 3950] = 1000000010556012716588907553;
        rates[ 3975] = 1000000010612789441371369043;
        rates[ 4000] = 1000000010669464688489416886;
        rates[ 4025] = 1000000010726038820040263233;
        rates[ 4050] = 1000000010782512196186493739;
        rates[ 4075] = 1000000010838885175169824929;
        rates[ 4100] = 1000000010895158113324739488;
        rates[ 4125] = 1000000010951331365092000772;
        rates[ 4150] = 1000000011007405283032047846;
        rates[ 4175] = 1000000011063380217838272275;
        rates[ 4200] = 1000000011119256518350177948;
        rates[ 4225] = 1000000011175034531566425160;
        rates[ 4250] = 1000000011230714602657760176;
        rates[ 4275] = 1000000011286297074979831462;
        rates[ 4300] = 1000000011341782290085893805;
        rates[ 4325] = 1000000011397170587739401474;
        rates[ 4350] = 1000000011452462305926491579;
        rates[ 4375] = 1000000011507657780868358802;
        rates[ 4400] = 1000000011562757347033522598;
        rates[ 4425] = 1000000011617761337149988016;
        rates[ 4450] = 1000000011672670082217301219;
        rates[ 4475] = 1000000011727483911518500818;
        rates[ 4500] = 1000000011782203152631966084;
        rates[ 4525] = 1000000011836828131443163102;
        rates[ 4550] = 1000000011891359172156289942;
        rates[ 4575] = 1000000011945796597305821848;
        rates[ 4600] = 1000000012000140727767957524;
        rates[ 4625] = 1000000012054391882771967477;
        rates[ 4650] = 1000000012108550379911445472;
        rates[ 4675] = 1000000012162616535155464050;
        rates[ 4700] = 1000000012216590662859635112;
        rates[ 4725] = 1000000012270473075777076530;
        rates[ 4750] = 1000000012324264085069285747;
        rates[ 4775] = 1000000012377964000316921287;
        rates[ 4800] = 1000000012431573129530493155;
        rates[ 4825] = 1000000012485091779160962996;
        rates[ 4850] = 1000000012538520254110254976;
        rates[ 4875] = 1000000012591858857741678240;
        rates[ 4900] = 1000000012645107891890261872;
        rates[ 4925] = 1000000012698267656873003228;
        rates[ 4950] = 1000000012751338451499030498;
        rates[ 4975] = 1000000012804320573079680371;
        rates[ 5000] = 1000000012857214317438491659;
        rates[ 5025] = 1000000012910019978921115695;
        rates[ 5050] = 1000000012962737850405144363;
        rates[ 5075] = 1000000013015368223309856554;
        rates[ 5100] = 1000000013067911387605883890;
        rates[ 5125] = 1000000013120367631824796485;
        rates[ 5150] = 1000000013172737243068609553;
        rates[ 5175] = 1000000013225020507019211652;
        rates[ 5200] = 1000000013277217707947715318;
        rates[ 5225] = 1000000013329329128723730871;
        rates[ 5250] = 1000000013381355050824564143;
        rates[ 5275] = 1000000013433295754344338876;
        rates[ 5300] = 1000000013485151518003044532;
        rates[ 5325] = 1000000013536922619155510237;
        rates[ 5350] = 1000000013588609333800305597;
        rates[ 5375] = 1000000013640211936588569081;
        rates[ 5400] = 1000000013691730700832764691;
        rates[ 5425] = 1000000013743165898515367617;
        rates[ 5450] = 1000000013794517800297479554;
        rates[ 5475] = 1000000013845786675527374380;
        rates[ 5500] = 1000000013896972792248974855;
        rates[ 5525] = 1000000013948076417210261020;
        rates[ 5550] = 1000000013999097815871610946;
        rates[ 5575] = 1000000014050037252414074493;
        rates[ 5600] = 1000000014100894989747580713;
        rates[ 5625] = 1000000014151671289519079548;
        rates[ 5650] = 1000000014202366412120618444;
        rates[ 5675] = 1000000014252980616697354502;
        rates[ 5700] = 1000000014303514161155502800;
        rates[ 5725] = 1000000014353967302170221464;
        rates[ 5750] = 1000000014404340295193434124;
        rates[ 5775] = 1000000014454633394461590334;
        rates[ 5800] = 1000000014504846853003364537;
        rates[ 5825] = 1000000014554980922647294184;
        rates[ 5850] = 1000000014605035854029357558;
        rates[ 5875] = 1000000014655011896600491882;
        rates[ 5900] = 1000000014704909298634052283;
        rates[ 5925] = 1000000014754728307233212158;
        rates[ 5950] = 1000000014804469168338305494;
        rates[ 5975] = 1000000014854132126734111701;
        rates[ 6000] = 1000000014903717426057083481;
        rates[ 6025] = 1000000014953225308802518272;
        rates[ 6050] = 1000000015002656016331673799;
        rates[ 6075] = 1000000015052009788878828253;
        rates[ 6100] = 1000000015101286865558285606;
        rates[ 6125] = 1000000015150487484371326590;
        rates[ 6150] = 1000000015199611882213105818;
        rates[ 6175] = 1000000015248660294879495575;
        rates[ 6200] = 1000000015297632957073876761;
        rates[ 6225] = 1000000015346530102413877471;
        rates[ 6250] = 1000000015395351963438059699;
        rates[ 6275] = 1000000015444098771612554646;
        rates[ 6300] = 1000000015492770757337647112;
        rates[ 6325] = 1000000015541368149954309419;
        rates[ 6350] = 1000000015589891177750685357;
        rates[ 6375] = 1000000015638340067968524580;
        rates[ 6400] = 1000000015686715046809567945;
        rates[ 6425] = 1000000015735016339441884188;
        rates[ 6450] = 1000000015783244170006158447;
        rates[ 6475] = 1000000015831398761621933006;
        rates[ 6500] = 1000000015879480336393800741;
        rates[ 6525] = 1000000015927489115417551681;
        rates[ 6550] = 1000000015975425318786273105;
        rates[ 6575] = 1000000016023289165596403599;
        rates[ 6600] = 1000000016071080873953741499;
        rates[ 6625] = 1000000016118800660979408115;
        rates[ 6650] = 1000000016166448742815766155;
        rates[ 6675] = 1000000016214025334632293755;
        rates[ 6700] = 1000000016261530650631414500;
        rates[ 6725] = 1000000016308964904054283846;
        rates[ 6750] = 1000000016356328307186532328;
        rates[ 6775] = 1000000016403621071363965932;
        rates[ 6800] = 1000000016450843406978224029;
        rates[ 6825] = 1000000016497995523482395247;
        rates[ 6850] = 1000000016545077629396591637;
        rates[ 6875] = 1000000016592089932313481533;
        rates[ 6900] = 1000000016639032638903781446;
        rates[ 6925] = 1000000016685905954921707380;
        rates[ 6950] = 1000000016732710085210385903;
        rates[ 6975] = 1000000016779445233707225354;
        rates[ 7000] = 1000000016826111603449247521;
        rates[ 7025] = 1000000016872709396578380147;
        rates[ 7050] = 1000000016919238814346710603;
        rates[ 7075] = 1000000016965700057121701072;
        rates[ 7100] = 1000000017012093324391365593;
        rates[ 7125] = 1000000017058418814769409273;
        rates[ 7150] = 1000000017104676726000330021;
        rates[ 7175] = 1000000017150867254964483131;
        rates[ 7200] = 1000000017196990597683109018;
        rates[ 7225] = 1000000017243046949323324453;
        rates[ 7250] = 1000000017289036504203077600;
        rates[ 7275] = 1000000017334959455796067168;
        rates[ 7300] = 1000000017380815996736626004;
        rates[ 7325] = 1000000017426606318824569415;
        rates[ 7350] = 1000000017472330613030008543;
        rates[ 7375] = 1000000017517989069498129080;
        rates[ 7400] = 1000000017563581877553935633;
        rates[ 7425] = 1000000017609109225706962029;
        rates[ 7450] = 1000000017654571301655947851;
        rates[ 7475] = 1000000017699968292293481503;
        rates[ 7500] = 1000000017745300383710610088;
        rates[ 7525] = 1000000017790567761201416374;
        rates[ 7550] = 1000000017835770609267563142;
        rates[ 7575] = 1000000017880909111622805195;
        rates[ 7600] = 1000000017925983451197469286;
        rates[ 7625] = 1000000017970993810142902264;
        rates[ 7650] = 1000000018015940369835887686;
        rates[ 7675] = 1000000018060823310883031179;
        rates[ 7700] = 1000000018105642813125114801;
        rates[ 7725] = 1000000018150399055641420686;
        rates[ 7750] = 1000000018195092216754024201;
        rates[ 7775] = 1000000018239722474032056911;
        rates[ 7800] = 1000000018284290004295939569;
        rates[ 7825] = 1000000018328794983621585414;
        rates[ 7850] = 1000000018373237587344574003;
        rates[ 7875] = 1000000018417617990064295840;
        rates[ 7900] = 1000000018461936365648068049;
        rates[ 7925] = 1000000018506192887235221305;
        rates[ 7950] = 1000000018550387727241158310;
        rates[ 7975] = 1000000018594521057361384012;
        rates[ 8000] = 1000000018638593048575507813;
        rates[ 8025] = 1000000018682603871151218019;
        rates[ 8050] = 1000000018726553694648228732;
        rates[ 8075] = 1000000018770442687922199432;
        rates[ 8100] = 1000000018814271019128627481;
        rates[ 8125] = 1000000018858038855726713746;
        rates[ 8150] = 1000000018901746364483201594;
        rates[ 8175] = 1000000018945393711476189463;
        rates[ 8200] = 1000000018988981062098917230;
        rates[ 8225] = 1000000019032508581063526585;
        rates[ 8250] = 1000000019075976432404795643;
        rates[ 8275] = 1000000019119384779483847985;
        rates[ 8300] = 1000000019162733784991836346;
        rates[ 8325] = 1000000019206023610953601168;
        rates[ 8350] = 1000000019249254418731304205;
        rates[ 8375] = 1000000019292426369028037391;
        rates[ 8400] = 1000000019335539621891407188;
        rates[ 8425] = 1000000019378594336717094581;
        rates[ 8450] = 1000000019421590672252390959;
        rates[ 8475] = 1000000019464528786599710033;
        rates[ 8500] = 1000000019507408837220076029;
        rates[ 8525] = 1000000019550230980936588320;
        rates[ 8550] = 1000000019592995373937862689;
        rates[ 8575] = 1000000019635702171781449432;
        rates[ 8600] = 1000000019678351529397228463;
        rates[ 8625] = 1000000019720943601090781625;
        rates[ 8650] = 1000000019763478540546742376;
        rates[ 8675] = 1000000019805956500832123050;
        rates[ 8700] = 1000000019848377634399619849;
        rates[ 8725] = 1000000019890742093090895767;
        rates[ 8750] = 1000000019933050028139841613;
        rates[ 8775] = 1000000019975301590175815296;
        rates[ 8800] = 1000000020017496929226859581;
        rates[ 8825] = 1000000020059636194722898437;
        rates[ 8850] = 1000000020101719535498912200;
        rates[ 8875] = 1000000020143747099798091677;
        rates[ 8900] = 1000000020185719035274971385;
        rates[ 8925] = 1000000020227635488998542076;
        rates[ 8950] = 1000000020269496607455342719;
        rates[ 8975] = 1000000020311302536552532106;
        rates[ 9000] = 1000000020353053421620940223;
        rates[ 9025] = 1000000020394749407418099573;
        rates[ 9050] = 1000000020436390638131256590;
        rates[ 9075] = 1000000020477977257380363298;
        rates[ 9100] = 1000000020519509408221049399;
        rates[ 9125] = 1000000020560987233147574896;
        rates[ 9150] = 1000000020602410874095763456;
        rates[ 9175] = 1000000020643780472445916617;
        rates[ 9200] = 1000000020685096169025709028;
        rates[ 9225] = 1000000020726358104113064837;
        rates[ 9250] = 1000000020767566417439015395;
        rates[ 9275] = 1000000020808721248190538424;
        rates[ 9300] = 1000000020849822735013378765;
        rates[ 9325] = 1000000020890871016014850891;
        rates[ 9350] = 1000000020931866228766623286;
        rates[ 9375] = 1000000020972808510307484860;
        rates[ 9400] = 1000000021013697997146093523;
        rates[ 9425] = 1000000021054534825263707061;
        rates[ 9450] = 1000000021095319130116896449;
        rates[ 9475] = 1000000021136051046640241741;
        rates[ 9500] = 1000000021176730709249010667;
        rates[ 9525] = 1000000021217358251841820063;
        rates[ 9550] = 1000000021257933807803280285;
        rates[ 9575] = 1000000021298457510006622716;
        rates[ 9600] = 1000000021338929490816310513;
        rates[ 9625] = 1000000021379349882090632705;
        rates[ 9650] = 1000000021419718815184281790;
        rates[ 9675] = 1000000021460036420950914938;
        rates[ 9700] = 1000000021500302829745698932;
        rates[ 9725] = 1000000021540518171427838973;
        rates[ 9750] = 1000000021580682575363091474;
        rates[ 9775] = 1000000021620796170426260951;
        rates[ 9800] = 1000000021660859085003681151;
        rates[ 9825] = 1000000021700871446995680519;
        rates[ 9850] = 1000000021740833383819032127;
        rates[ 9875] = 1000000021780745022409388199;
        rates[ 9900] = 1000000021820606489223699321;
        rates[ 9925] = 1000000021860417910242618463;
        rates[ 9950] = 1000000021900179410972889943;
        rates[ 9975] = 1000000021939891116449723415;
        rates[10000] = 1000000021979553151239153027;
    }

}
