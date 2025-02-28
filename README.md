## Überblick

[![Latest GitHub Release](https://img.shields.io/github/release/Joshua-Riek/ubuntu-rockchip.svg?label=Latest%20Release)](https://github.com/Joshua-Riek/ubuntu-rockchip/releases/latest)
[![Total GitHub Downloads](https://img.shields.io/github/downloads/Joshua-Riek/ubuntu-rockchip/total.svg?&color=E95420&label=Total%20Downloads)](https://github.com/Joshua-Riek/ubuntu-rockchip/releases)
[![Nightly GitHub Build](https://github.com/Joshua-Riek/ubuntu-rockchip/actions/workflows/nightly.yml/badge.svg)](https://github.com/Joshua-Riek/ubuntu-rockchip/actions/workflows/nightly.yml)

Ubuntu Rockchip ist ein Community-Projekt, das Ubuntu auf Rockchip-Hardware portiert, mit dem Ziel, eine stabile und voll funktionsfähige Umgebung bereitzustellen.

## Highlights

* Verfügbar für Ubuntu 22.04 LTS (mit Rockchip Linux 5.10) und Ubuntu 24.04 LTS (mit Rockchip Linux 6.1)
* Paketverwaltung über apt mit den offiziellen Ubuntu-Repositorys
* Erhalte alle Updates und Änderungen über apt
* Desktop-Ersteinrichtungsassistent für Benutzereinrichtung und Konfiguration
* 3D-Hardwarebeschleunigung unterstützt durch panfork
* Voll funktionsfähiger GNOME-Desktop mit Wayland
* Chromium-Browser mit flüssiger 4K-YouTube-Videowiedergabe
* MPV-Videoplayer, der flüssige 4K-Videowiedergabe ermöglicht

## Installation

Stelle sicher, dass du eine gute, zuverlässige und schnelle SD-Karte verwendest. Wenn du beispielsweise Boot- oder Stabilitätsprobleme hast, liegt dies meist entweder an einer unzureichenden Stromversorgung oder an deiner SD-Karte (schlechte Karte, schlechter Kartenleser, etwas ist beim Schreiben des Images schiefgelaufen oder die Karte ist zu langsam).

Lade das Ubuntu-Image für dein spezifisches Board aus dem neuesten [Release](https://github.com/Joshua-Riek/ubuntu-rockchip/releases) auf GitHub oder von der dedizierten Download-[Website](https://joshua-riek.github.io/ubuntu-rockchip-download/) herunter. Schreibe dann das xz-komprimierte Image (ohne vorherige Entpackung) auf deine SD-Karte mit [USBimager](https://bztsrc.gitlab.io/usbimager/) oder [balenaEtcher](https://www.balena.io/etcher), da diese im Gegensatz zu anderen Tools die Schreibvorgänge validieren können, was dich vor beschädigten SD-Karteninhalten bewahrt.

## System starten

Stecke deine SD-Karte in den Steckplatz auf dem Board und schalte das Gerät ein. Der erste Start kann bis zu zwei Minuten dauern, also habe bitte etwas Geduld.

## Anmeldeinformationen

Für Ubuntu Server kannst du dich über HDMI, eine serielle Konsolenverbindung oder SSH anmelden. Der vordefinierte Benutzer ist `ubuntu` und das Passwort ist `ubuntu`.

Für Ubuntu Desktop musst du dich über HDMI verbinden und den Einrichtungsassistenten durchlaufen.

## Unterstütze das Projekt

Es gibt ein paar Dinge, die du tun kannst, um das Projekt zu unterstützen:

* Markiere das Repository mit einem Stern und folge mir auf GitHub
* Teile und bewerte auf Seiten wie Twitter, Reddit und YouTube
* Melde alle Fehler, Probleme oder Ungereimtheiten, die du findest (einige Fehler kann ich möglicherweise nicht beheben)
* Spende mir auf GitHub; jeder Beitrag wird sehr geschätzt

Diese Dinge motivieren mich, die Entwicklung fortzusetzen und geben mir die Bestätigung, dass meine Arbeit geschätzt wird. Vielen Dank im Voraus!

---
> Ubuntu ist eine Marke von Canonical Ltd. Rockchip ist eine Marke von Fuzhou Rockchip Electronics Co., Ltd. Das Ubuntu Rockchip-Projekt ist nicht mit Canonical Ltd oder Fuzhou Rockchip Electronics Co., Ltd. verbunden. Alle anderen Produktnamen, Logos und Marken sind Eigentum ihrer jeweiligen Inhaber. Der Name Ubuntu ist im Besitz von [Canonical Limited](https://ubuntu.com/).
