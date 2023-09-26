/*
 *	ISNIP For T5(Black Ops 1) 
 *	Edit by Sul6an#3330 
 *  most code here are from iw4x mods and forum.plutonium.pw
 *	anitCamp by https://forum.plutonium.pw/user/kalitos
 *  everything else is from https://github.com/isnipe/iSnipe
 *  i have't tested it yet but i think it works
 */
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	
	level thread onPlayerConnect();
	level.enableAntiHardScop = true;
	level.scopTime = 10; // time to take unscop 
	level.enableRestockAmmo = true; // give ammo every time he shot fire 
	level.enbaleAntiCamp = true;
	level.meleeKnifeRange = 5; // 0 - 100 rang of melee knife
}
/*
 *	onPlayerConnect()
 *
 *		Main Thread that starts a thread for each player once they are connected
 */
onPlayerConnect()
{
	while (true)
	{
		level waittill("connected", player);		// wait for player to connect
		player iPrintLnBold("Welcome to ^1ISNIP"); // change message if you want or remove this line to disable
		player thread onPlayerSpawned();
	}
}

/*
 *	onPlayerSpawned()
 *
 *		Player thread started by onPlayerConnect
 *		Alive until player disconnects
 */
onPlayerSpawned()
{
	self endon("disconnect");
	level endon("game_ended");
	while (true)
	{
		self waittill("spawned_player");
		self thread applyGameMode();
		if(level.enbaleAntiCamp) self thread watch_anti_camp();
		if(level.enableAntiHardScop) self thread monitorads(level.scopTime);
		if(level.enableRestockAmmo) self thread ammoLoop();
		//PERKS:
		self clearperks();
		self setperk("specialty_healthregen");
		self setperk("specialty_fastreload");
		self setperk("specialty_fallheight");
		self setperk("specialty_fastads");
		self setperk("specialty_longersprint");
		self setperk("specialty_scavenger");

	}
}

watch_anti_camp()
{
	self endon("disconnect");
	self endon("death");
	self endon("joined_spectators");
	level endon("destroy_bar");
	level endon("game_ended");
	//if(getintdvar("scr_anticamp"!=1)
	//return;
	self.camping = 0;
	if(!isDefined(self.bar))
	{
		self.bar = self maps\mp\gametypes\_hud_util::createBar((1,1,1), 64, 8);
		self.bar maps\mp\gametypes\_hud_util::setPoint("CENTER", undefined, 0, 230);
	}
	while(isAlive(self))
	{
		oldorg = self.origin;
		wait .2;
		if(distance(oldorg, self.origin) < 2.5)
			self.camping += 0.015;
		else
			self.camping -= 0.0055;
		if(self.camping > 1)
			self.camping = 1;
		else if(self.camping < 0)
		self.camping = 0;
		
		self.bar maps\mp\gametypes\_hud_util::updateBar(self.camping);
		if(self.camping == 1)
		{
			self iprintlnbold("^2Move ^7or you will be ^1killed!");
			oldorg = self.origin;
			wait 5;
			if(distance(oldorg, self.origin) < 150)
			{
				self.bar maps\mp\gametypes\_hud_util::updateBar(0);
				self.bar destroy();
				self suicide();
				level notify("destroy_bar");
				
			}
		}
	}
}
/*
 *	restrictWeapons()
 *
 *		Restrict weapons and offhand, replace if disallowed encountered
 */
restrictWeapons()
{

	
	 while (isAlive(self)) {
		wait .5;
	//remove nades
	self takeWeapon("frag_grenade_mp");
	self takeWeapon("sticky_grenade_mp");
	self takeWeapon("claymore_mp");
	self takeWeapon("flash_grenade_mp");
	self takeWeapon("concussion_grenade_mp");
	self takeWeapon("smoke_center_mp");
	
	weapon = self getCurrentWeapon(); 
		if(!isSubStr(weapon, "l96a1") && !isSubStr(weapon, "knife_ballistic_mp") && !isSubStr(weapon, "briefcase") ) {
		self takeWeapon(weapon);
		self giveWeapon("l96a1_extclip_mp");
		self giveWeapon("knife_held_mp");
		self giveMaxAmmo("l96a1_extclip_mp");
		//with varible zoom
		self giveWeapon("knife_ballistic_mp");
		// wait .1 second as switchToWeapon doesn't seem to work when called directly after giveWeapon
		 //wait(.1);
		 self switchToWeapon("l96a1_extclip_mp");
		}
	
	 }
}


takeAmmo(slot)
{
	if (slot == "primary")
	{
		self setWeaponAmmoClip(self.primaryWeapon, 0);
		self setWeaponAmmoStock(self.primaryWeapon, 0);
	}
	else if (slot == "secondary")
	{
		// Check for akimbo and take ammo of both akimbo weapons if encountered
		if (isSubstr(self.secondaryWeapon, "akimbo"))
		{
			self setWeaponAmmoClip(self.secondaryWeapon, 0, "left");
			self setWeaponAmmoClip(self.secondaryWeapon, 0, "right");
		} else {
			self setWeaponAmmoClip(self.secondaryWeapon, 0);
		}

		self setWeaponAmmoStock(self.secondaryWeapon, 0);
	}

}


monitorads(time)
{
	self endon("disconnect");
	level endon("game_ended");

	adstime = 0;

	for(;;)
	{
		if (self playerAds() == 1) {
			adstime++;
		} else if (self playerAds() == 0 && adstime != 0) {
			adstime = 0;
		}

		// to change time, do (second divided by 0.05)
		// ex: 0.5 seconds divided by 0.05 = 10
		if (adstime == time)
		{
			adstime = 0;
			self allowads(false);
			while (self playerAds() != 0) {
				wait 0.05;
			}
			self allowads(true);
		}
		wait 0.05;
	}
}

/*
 *	dvars()
 *
 *		Set required dvars
 */
dvars()
{
	/*
	 *	Disable melee
	 *		WONTFIX:
	 *			Can't break windows with knife
	 *				Fixing this would require hooking into the damage function and
	 *				settings damage on player hit to 0 for the knife
	 */
	setDvar("player_meleeRange", level.meleeKnifeRange);
	/*
	 *	/weather clear
	 *	r_fog
	 *		removes main dust on rust
	 *	fx_enable
	 *		removes particles etc
	 *		also fixed black boxes with fullbright on mp_nuked
	 *		additonally this seems to change the kill points color to gray?
	 */ 
	self setClientDvar("r_fog", 1);
	self setClientDvar("fx_enable", 1);
}

/*
 *	applyGameMode()
 *
 *		Apply game mode on player spawn
 *		Restrict weapons during class selection grace period
 */
applyGameMode()
{	
	self dvars();
	self restrictWeapons();
	//while (true) {

	wait(.5);
	//}

}

/*
 *	ammoLoop()
 *
 *		Restock ammo on shot fired
 *			Excluding secondary weapon
 */
ammoLoop()
{
	while (true)
	{
		self waittill("weapon_fired");
		ammoWeapon = self getCurrentWeapon();

		if (ammoWeapon != self.secondaryWeapon)
		{
			self giveMaxAmmo(ammoWeapon);
		}
	}
}

//GUNS
/*
1 defaultweapon_mp
2 mp7_mp
4 pdw57_mp
6 vector_mp
8 insas_mp
10 qcw05_mp
12 evoskorpion_mp
14 peacekeeper_mp
16 tar21_mp
20 type95_mp
24 sig556_mp
28 sa58_mp
32 hk416_mp
36 scar_mp
40 saritch_mp
44 xm8_mp
48 an94_mp
52 870mcs_mp
53 saiga12_mp
54 ksg_mp
55 srm1216_mp
56 mk48_mp
58 qbb95_mp
60 lsat_mp
62 hamr_mp
64 svu_mp
65 dsr50_mp
66 ballista_mp
67 as50_mp
68 kard_dw_mp
70 fnp45_dw_mp
72 fiveseven_dw_mp
74 judge_dw_mp
76 beretta93r_dw_mp
78 fiveseven_mp
79 fnp45_mp
80 beretta93r_mp
81 judge_mp
82 kard_mp
83 m32_mp
84 smaw_mp
85 fhj18_mp
86 usrpg_mp
87 knife_held_mp
88 minigun_mp
89 riotshield_mp
90 crossbow_mp
91 knife_ballistic_mp
92 frag_grenade_mp
93 concussion_grenade_mp
94 sticky_grenade_mp
95 willy_pete_mp
96 hatchet_mp
97 sensor_grenade_mp
98 bouncingbetty_mp
99 emp_grenade_mp
100 satchel_charge_mp
101 proximity_grenade_mp
102 claymore_mp
103 pda_hack_mp
104 flash_grenade_mp
105 trophy_system_mp
106 tactical_insertion_mp
107 destructible_car_mp
108 explodable_barrel_mp
109 vcs_controller_mp
110 knife_mp
111 dogs_mp
112 dog_bite_mp
113 explosive_bolt_mp
114 scavenger_item_mp
115 scavenger_item_hack_mp
116 smoke_center_mp
117 proximity_grenade_aoe_mp
118 briefcase_bomb_mp
119 briefcase_bomb_defuse_mp
120 cobra_20mm_mp
121 inventory_supplydrop_mp
122 supplydrop_mp
123 ai_tank_drone_rocket_mp
124 ai_tank_drone_gun_mp
125 killstreak_ai_tank_mp
126 inventory_ai_tank_drop_mp
127 ai_tank_drop_mp
128 radar_mp
129 counteruav_mp
130 radardirection_mp
131 emp_mp
132 cobra_20mm_comlink_mp
133 heli_gunner_rockets_mp
134 littlebird_guard_minigun_mp
135 helicopter_comlink_mp
136 helicopter_guard_mp
137 helicopter_player_gunner_mp
138 chopper_minigun_mp
139 inventory_minigun_mp
140 inventory_m32_mp
141 missile_drone_projectile_mp
142 inventory_missile_drone_mp
143 missile_drone_mp
144 missile_swarm_projectile_mp
145 missile_swarm_mp
146 planemortar_mp
147 rc_car_weapon_mp
148 rcbomb_mp
149 remote_missile_missile_mp
150 remote_missile_bomblet_mp
151 remote_missile_mp
152 remote_mortar_missile_mp
153 remote_mortar_mp
154 qrdrone_turret_mp
155 killstreak_qrdrone_mp
156 straferun_gun_mp
157 straferun_rockets_mp
158 straferun_mp
159 auto_gun_turret_mp
160 microwave_turret_mp
161 killstreak_remote_turret_mp
162 autoturret_mp
163 turret_drop_mp
164 microwaveturret_mp
165 microwaveturret_drop_mp
*/