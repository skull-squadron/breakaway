<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1214285189471" ID="Freemind_Link_766605356" MODIFIED="1214285352599" TEXT="Breakaway">
<node CREATED="1214285233315" HGAP="30" ID="_" MODIFIED="1214372322706" POSITION="right" TEXT="Triggers" VSHIFT="-176">
<node CREATED="1214285413463" HGAP="27" ID="Freemind_Link_1870665016" MODIFIED="1214371313264" TEXT="Current" VSHIFT="84">
<node CREATED="1214285457688" ID="Freemind_Link_100070575" MODIFIED="1214285685674" TEXT=".plist storage method" VSHIFT="1"/>
<node CREATED="1214285495551" ID="Freemind_Link_29021308" MODIFIED="1214285948104" TEXT="Limited AS functionality" VSHIFT="1"/>
<node CREATED="1214285541270" ID="Freemind_Link_583814426" MODIFIED="1214285687538" TEXT="Easy to use"/>
</node>
<node CREATED="1214285441788" HGAP="21" ID="Freemind_Link_1483320957" MODIFIED="1214371310520" TEXT="Future" VSHIFT="-18">
<icon BUILTIN="idea"/>
<node CREATED="1214285552388" ID="Freemind_Link_1816653609" MODIFIED="1214372171537" TEXT="plugin architecture" VSHIFT="-24">
<node CREATED="1214358893864" ID="Freemind_Link_1582530498" MODIFIED="1214371303695" TEXT="types" VSHIFT="67">
<node CREATED="1214358760011" ID="Freemind_Link_355774799" MODIFIED="1214358766329" TEXT="instance plugins">
<node CREATED="1214358783988" ID="Freemind_Link_81822270" MODIFIED="1214359694528" TEXT="designed to be used multiple times (like the current AS implementation)"/>
<node CREATED="1214358854860" ID="Freemind_Link_1455846096" MODIFIED="1214359694528" TEXT="added to plugins &quot;add new item&quot; context menu button"/>
</node>
<node CREATED="1214358767310" HGAP="24" ID="Freemind_Link_357457346" MODIFIED="1214358911674" TEXT="single shot plugins" VSHIFT="-3">
<node CREATED="1214358820115" ID="Freemind_Link_1539605868" MODIFIED="1214358835691" TEXT="designed to be used only once"/>
<node CREATED="1214358835997" ID="Freemind_Link_453557091" MODIFIED="1214358852228" TEXT="automatically added into plugins list"/>
</node>
</node>
<node CREATED="1214358963998" ID="Freemind_Link_462792182" MODIFIED="1214371307719" TEXT="control" VSHIFT="1">
<node CREATED="1214358990023" ID="Freemind_Link_1355328097" MODIFIED="1214359012141" TEXT="Breakaway handles enable/disabling"/>
<node CREATED="1214359937109" ID="Freemind_Link_613313725" MODIFIED="1214371231988" TEXT="Plugins must control their own logic for determining when it is OK to play with audio. For example, you can&apos;t have iTunes start playing when VLC is playing. The plugin dev must provide process checks to see what is running and what is frontmost before going on and manipulating AV players."/>
</node>
<node CREATED="1214371249767" ID="Freemind_Link_1354363653" MODIFIED="1214371571836" TEXT="runtime paramaters" VSHIFT="7">
<node CREATED="1214371320716" ID="Freemind_Link_96300381" MODIFIED="1214371479641" TEXT="inPropertyID on manipulate proc" VSHIFT="1"/>
<node CREATED="1214371446202" ID="Freemind_Link_1939790996" MODIFIED="1214371461800" TEXT="NSApp self">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1214371530982" ID="Freemind_Link_1280983300" MODIFIED="1214372166801" TEXT="linkage &amp; init" VSHIFT="6">
<node CREATED="1214371604705" ID="Freemind_Link_1156276826" MODIFIED="1214371638745" TEXT="instantiated after the program loads" VSHIFT="-11"/>
<node CREATED="1214371640705" ID="Freemind_Link_571534331" MODIFIED="1214371768233" TEXT="linked directly into the listener proc fn"/>
</node>
<node CREATED="1214371803737" ID="Freemind_Link_1763729854" MODIFIED="1214372165553" TEXT="strict protocol vars" VSHIFT="-9">
<node CREATED="1214371833015" ID="Freemind_Link_588304239" MODIFIED="1214372188641" TEXT="name" VSHIFT="-10"/>
</node>
<node CREATED="1214372111802" ID="Freemind_Link_121020325" MODIFIED="1214372169114" TEXT="preference injection" VSHIFT="-20">
<node CREATED="1214372120656" ID="Freemind_Link_259322677" MODIFIED="1214372190593" TEXT="need code to let plugins inject preferences into main preference window" VSHIFT="-8"/>
</node>
</node>
<node CREATED="1214285567013" ID="Freemind_Link_668834314" MODIFIED="1214371544218" TEXT="harder to use for standard consumer" VSHIFT="17"/>
<node CREATED="1214285586201" ID="Freemind_Link_856986852" MODIFIED="1214285691242" STYLE="fork" TEXT="Infinite functionality"/>
</node>
</node>
</node>
</map>
