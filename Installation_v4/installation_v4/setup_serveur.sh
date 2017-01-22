#!/bin/bash

#---------- Script de mise en place du Serveur de Paramétrage Web -----------#
#-- A Exécuter en root !


#==== Récupération du nom du boitier ====#
echo "Récupération du nom du dispositif..."
nom="$(hostname)"
echo "Dispositif trouvé : \"$nom\"."
echo " "

#==== Installation du serveur ====
echo "==> Installation du serveur..."
sudo apt-get install apache2 php5 libapache2-mod-php5
echo "Lancement du serveur..."
sudo a2enmod php5
sudo /etc/init.d/apache2 force-reload
echo "==> Installation du serveur terminée."
echo " "


#=== Suppression de index.html ===
echo "Suppression des fichiers de base."
sudo rm -f /var/www/*
echo " "

#==== Ajout des scripts ===
echo "===> Générations des scripts de configurations..."
#--- config_vlc ---
sudo echo "#!/bin/bash

export DISPLAY=:0
cvlc -f \$1 &

sleep 1 
killall -u www-data -o 2s vlc
killall -u www-data sm
killall -u www-data ssvncviewer" > /var/www/config_vlc.sh


#--- config_vnc ---
sudo echo "#!/bin/bash

export DISPLAY=:0
ssvncviewer -fullscreen -viewonly \$1 \$2 \$3 &

sleep 1 
killall -u www-data -o 2s ssvncviewer
killall -u www-data sm
killall -u www-data vlc" > /var/www/config_vnc.sh


#--- config_sm ---
sudo echo "#!/bin/bash

cle=\"\"

genereCle(){
	M=\"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\"
	i=0
	while [ \"\$i\" -le \"7\" ]
	do  
		cle=\"\$cle\${M:\$((\$RANDOM%\${#M})):1}\"
	  	i=\$((\$i+1))
	done
}

export DISPLAY=:0
genereCle
sudo sed -i \"s/\(wpa_passphrase=\).*/\1\$cle/\" /etc/hostapd/hostapd.conf
sudo /home/ubuntu/.restart_ap.sh
sleep 1
/usr/games/sm -b black -f white \" $nom 
- 
 \$cle \" -n \"serif\" &
sleep 1
killall -u www-data -o 2s sm
killall -u www-data vlc
killall -u www-data ssvncviewer
/home/ubuntu/.attente_user.sh &
" > /var/www/config_sm.sh


echo "Affectation des droits d'éxécution."
sudo chmod 775 /var/www/*.sh
echo "===> Génération des scripts terminée."
echo " "



echo "==> Génération des fichiers Web..."
echo "Génération du PHP"
sudo echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
<?
/*----- Administration de la page --------*/
\$ipAutorisee=\"192.168.1.2\";
\$nomBoitier=\"$nom\";


\$config=\$_POST['config'];
\$port=\$_POST['port'];
\$url=\$_POST['url'];
\$scale=\$_POST['scale'];
?>




<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"fr\" lang=\"fr\">
    <head>
    	<link rel=\"stylesheet\" href=\"style.css\" />
        <title><? echo \"\$nomBoitier\" ?></title>
        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
        <script type=\"text/javascript\">
	<!--
	
	function trim (myString)
	{
		return myString.replace(/^\s+/g,'').replace(/\s+$/g,'')
	} 
	
	function initialisation(){
		if (document.getElementById(\"vnc\").checked==true){
			document.getElementById(\"ligne_port\").style.visibility=\"visible\";
		}
		else if (document.getElementById(\"vlc2\").checked==true){
			document.getElementById(\"ligne_lien\").style.visibility=\"visible\";
		}
	}
	
	function verification(){
		if (document.getElementById(\"vlc2\").checked==true
			&& trim(document.getElementById(\"url\").value)==\"\" ){
			alert(\"Veuillez préciser le lien vers la vidéo\");
			return false;
		}
		else if (document.getElementById(\"vnc\").checked==true){
			var num = trim(document.getElementById(\"port\").value);
			if (num != \"\" && parseInt(num) != num){
				alert(\"Le numéro de port doit être un nombre !\");
				return false;
			}			
		}
		return true;
	}

	function activeVNC(){
		document.getElementById(\"vnc\").checked=true;
		document.getElementById(\"ligne_lien\").style.visibility=\"hidden\";
		document.getElementById(\"ligne_port\").style.visibility=\"visible\";	
	}
	
	function activeVLC1(){
		document.getElementById(\"vlc\").checked=true;
		document.getElementById(\"ligne_lien\").style.visibility=\"hidden\";
		document.getElementById(\"ligne_port\").style.visibility=\"hidden\";	
	}
	
	function activeVLC2(){
		document.getElementById(\"vlc2\").checked=true;
		document.getElementById(\"ligne_lien\").style.visibility=\"visible\";
		document.getElementById(\"ligne_port\").style.visibility=\"hidden\";	
	}
	
	// -->
	</script>
    </head>
    <div id=\"conteneur\">
    <body onload=\"initialisation()\">   
        <?
        if ( \$_SERVER['REMOTE_ADDR'] == \$ipAutorisee){
        ?>
        <div id=\"header\">
        	<table cellspacing=\"0\" cellpadding=\"20\" class=\"tabcenter\">
        	<tr>
       		<td valign=\"top\"><img src=\"proj.png\"  width=\"100\" height=\"104\" /></td>
        	<td><h1>Configuration de <? echo \"\$nomBoitier\" ?></h1></td>
        	</tr>
        	</table>
        </div>
        
        <div id=\"center\">      
        <form onsubmit=\"return verification()\" method=\"post\" action=\"index.php\">
        	<img id=\"left\" src=\"logo.gif\"/>
		<table id=\"content\">
			<tr>
			<td colspan=\"3\"><h3>Services</h3></td> 
			</tr>
			<tr onclick=\"activeVNC()\">
			<td><input type=\"radio\" name=\"config\"
				value=\"vnc\" id=\"vnc\" <?if( trim(\$config)==\"\" || \$config==\"vnc\"){ ?>CHECKED<? } ?>/></td>
			<td colspan=\"3\"><label for=\"vnc\">Partage d'écran (VNC)</label></td>
			</tr>
			<tr id=\"ligne_port\" style=\"visibility:hidden\">
			<td></td>
			<td></td>
			<td><label for=\"url\">Port &nbsp;&nbsp;</label>
			<input type=\"text\" name=\"port\" id=\"port\" size=\"5\" value=\"<? echo \$port; ?>\"/></td>
			<td class=\"info\" colspan=\"2\">
			<input type=\"checkbox\" name=\"scale\" id=\"scale\"
				value=\"true\" <? if (trim(\$scale)==\"true\"){ ?> CHECKED<? } ?> />
			<label for=\"scale\">Ajuster l'image</label>
			<span>Réduit les performances graphiques !</span>
			</td>
			</tr>
			<tr onclick=\"activeVLC1()\">
			<td><input type=\"radio\" name=\"config\" 
			value=\"vlc\" id=\"vlc\" <?if(\$config==\"vlc\"){ ?>CHECKED<? } ?>/></td>
			<td colspan=\"3\"><label for=\"vlc\">Diffusion de vidéo (VLC)</label></td>
			</tr>
			<tr><td><br/></td></tr>
			<tr onclick=\"activeVLC2()\">
			<td><input type=\"radio\" name=\"config\" 
			value=\"vlc2\" id=\"vlc2\" <?if(\$config==\"vlc2\"){ ?>CHECKED<? } ?>/></td>
			<td colspan=\"3\"><label for=\"vlc2\">Lecture de vidéos sur Internet (VLC)</label></td>
			</tr>
			<tr style=\"visibility:hidden\" id=\"ligne_lien\">
			<td></td>
			<td></td>
			<td><label for=\"url\">Lien vers la vidéo</label></td>
			<td><input type=\"text\" name=\"url\" id=\"url\" size=\"30\"/></td>
			</tr>
			<tr>
			<td colspan=\"3\"><input type=\"submit\" value=\"Valider\" /></td>
			</tr>
			<tr><td><br/></td></tr>
			<tr>
			<td colspan=\"4\">
			<a href=\"https://ensiwiki.ensimag.fr/index.php/Utilisation_de_la_connexion_WiFi_aux_videoprojecteurs\">Manuel d'utilisation</a>
			</td>
			</tr>
		</table>
	</form>
	<?
	    	if(trim(\$config) != \"\"){
	    		\$descriptorspec = array(
				0 => array(\"pipe\", \"r\"), // stdin
				1 => array(\"pipe\", \"w\"), // stdout
				2 => array(\"pipe\", \"w\") // stderr
			);
			
		if(\$config == \"vlc\"){
	    			\$flux=\"http://\".\$ipAutorisee.\":8080\";
	    			\$process = proc_open(\"/var/www/config_vlc.sh \$flux\", \$descriptorspec, \$pipes);
	    			if (is_resource(\$process)) {
					echo \"<h4>Le flux VLC a bien été envoyé</h4>\";
				}
				else{
					echo \"<h4>/!\\\\  Erreur dans la transmission du flux</h4>\";
				}
	    		}
	    		elseif(\$config == \"vlc2\"){
	    			\$process = proc_open(\"/var/www/config_vlc.sh \$url\", \$descriptorspec, \$pipes);
	    			if (is_resource(\$process)) {
					echo \"<h4>Le flux VLC a bien été envoyé</h4>\";
				}
				else{
					echo \"<h4>/!\\\\  Erreur dans la transmission du flux</h4>\";
				}
	    		}
	    		elseif(\$config == \"vnc\"){
	    			if(trim(\$port) == \"\"){
	    				\$flux=\$ipAutorisee.\":5900\";
	    			}
	    			else{
	    				\$flux=\$ipAutorisee.\":\".\$port;
	    			}
	    			if(trim(\$scale)==\"true\"){
					\$flux=\"-scale 1280x720 \".\$flux;
				}	    			
	    			\$process = proc_open(\"/var/www/config_vnc.sh \$flux\", \$descriptorspec, \$pipes);
	    			if (is_resource(\$process)) {
					echo \"<h4>La connexion VNC a été démarrée correctement</h4>\";
				}
				else{
					echo \"<h4>/!\\\\  Erreur dans la connection VNC</h4>\";
				}
	    		}
	    	}
	 	echo \"</div>\";
	}
	else{?>
		
		<div id=\"header\">
        		<table cellspacing=\"0\" cellpadding=\"20\" class=\"tabcenter\">
        		<tr>
       			<td valign=\"top\"><img src=\"proj.png\"  width=\"100\" height=\"104\" /></td>
        		<td><h1>Configuration de <? echo \"\$nomBoitier\" ?></h1></td>
        		</tr>
        		</table>
       		</div>
		
		<div id=\"center\">
			<h3>Authentification échouée</h3>
			<p>Vous n'êtes pas connecté au vidéoprojecteur \"<? echo \"\$nomBoitier\" ?>\".
			<br/>
			Vous n'avez pas le droit d'accéder à cette page !
			</p>
		</div>
	<?
	}
	?>
	<div id=\"footer\"> 
	Martin Chapsal &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Thomas Delahodde &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Thomas Moreschi &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Laurent Ougier-Simonin
	</div>
    	</body>
   	</div>
</html>
" > /var/www/index.php


echo "Génération du CSS"
sudo echo "#conteneur { 
	position:relative; 
	width:998px; 
	margin:0 auto; 
}
#header { 
	text-align: center;
	background-color:#5a7fa9; 
} 
#center { 
	margin-top:20px;
	overflow:hidden; 
	width:100%; 
	background:white repeat-y; 
} 
#left { 
	float:left; 
	width:300px; 
} 
#content { 
	margin-left:320px; 
	background-color:white; 
	padding:10px;
	margin:5px;
} 
#footer { 
	text-align: center;
	margin-top: 20px;
	background-color:#95add9; 
} 

.tabcenter{
   margin-left:auto;
   margin-right:auto;
}


td.info span{
	display:none;
}

td.info:hover span{
	display:inline;
	border:1px solid #000;
	background-color:orange;
	color:#000;
	text-align:justify;
	font-weight:none;
	padding:5px;
}
" > /var/www/style.css


#=== Images ===#
echo "Copie des images..."
sudo cp logo.gif /var/www/logo.gif
sudo cp proj.png /var/www/proj.png
echo " "



#==== Ajout des droits ===
echo "==> Mise en place des droits du serveur..."
sudo echo " " >> /etc/sudoers
sudo echo "# Web server gains root privileges " >> /etc/sudoers
sudo echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "Changement du groupe du dossier racine du serveur..."
sudo chgrp -R www-data /var/www/
sudo chown -R www-data /var/www/
sudo usermod -a -G audio www-data
sudo usermod -a -G video www-data
export DISPLAY=:0
xhost local:www-data
echo "==> Definition du serveur en temps qu'utilisateur par défaut."
#sudo sed -i "s/\(default_user       \).*/\1 www-data/" /etc/slim.conf #modif 1
echo " "

echo " "
echo ">>>>>>> Installation sur serveur terminée <<<<<<<"
sleep 1
echo " "
echo "---> Configuration de l'affichage par défaut"
sudo echo "#!/bin/bash

export DISPLAY=:0
unclutter -idle 0 &
xset dpms force on
xset -dpms
xset s off
xset s noblank
xhost local:www-data
sleep 2
sudo /usr/games/sm -b blue -f white \" 
 $nom 
 \" &
sleep 10
/var/www/config_sm.sh
sleep 2
xscreensaver-command -exit

" > /home/pi/.demarrage.sh
sudo chmod a+x /home/pi/.demarrage.sh
sudo echo "@/home/pi/.demarrage.sh" >> /etc/lightdm/lightdm.conf #modif2

sudo echo "#!/bin/bash
res=\"\$(cat /var/lib/dhcp/dhcpd.leases | wc -l)\"

while [ \$res -eq 5 ]
do
sleep 5
res=\"\$(cat /var/lib/dhcp/dhcpd.leases | wc -l)\"
done

sudo killall -u www-data sm
bash /home/pi/.attente_deco.sh &

" > /home/pi/.attente_user.sh
sudo chmod a+x /home/pi/.attente_user.sh

sudo echo "#!/bin/bash

res=\"\$(sudo hostapd_cli all_sta)\"

while [ \"\$res\" != \"Selected interface 'wlan0'\" ]
do
sleep 30
res=\"\$(sudo hostapd_cli all_sta)\"
done

/var/www/config_sm.sh
" > /home/pi/.attente_deco.sh
sudo chmod a+x /home/pi/.attente_deco.sh






