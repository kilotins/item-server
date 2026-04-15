# Debian 12 Installation — Lenovo P15s

## Forutsetninger

- Lenovo P15s med Windows 10 (blir overskrevet)
- USB-minnepinne (minst 2 GB)
- Nettverkstilkobling (kablet anbefales under installasjon)

## 1. Last ned Debian 12

Last ned **netinst** ISO fra:
https://www.debian.org/download

Filen heter noe som: `debian-12.x.x-amd64-netinst.iso` (~600 MB)

## 2. Lag bootbar USB

Pa Windows, bruk **Rufus**:
1. Last ned Rufus fra https://rufus.ie
2. Sett inn USB-pinne
3. Velg Debian ISO
4. Klikk Start
5. Vent til ferdig

## 3. BIOS-innstillinger (Lenovo P15s)

Start maskinen og trykk **F1** for BIOS Setup:

| Innstilling | Verdi | Hvorfor |
|-------------|-------|---------|
| Boot → Boot Mode | UEFI | Standard for Debian 12 |
| Security → Secure Boot | **Disabled** | Kan blokkere Debian-installasjon |
| Config → Power → After Power Loss | **Power On** | Starter automatisk etter strombrudd |
| Config → Power → Lid Close Action | **Do Nothing** | Kjorer med lokket lukket |
| Boot → Boot Priority | USB forst | For a boote fra USB |

Lagre og restart (F10).

## 4. Installer Debian

1. Boot fra USB
2. Velg **Install** (ikke Graphical Install — raskere)
3. Sprak: English
4. Lokasjon: Norway
5. Tastatur: Norwegian (eller det du foretrekker)
6. Hostname: `item-server`
7. Domain: `item.lan`
8. Root-passord: velg et sterkt passord
9. Ny bruker: `eric` (eller ditt navn)
10. Partisjonering: **Guided - use entire disk** (sletter Windows!)
11. Pakkevelger:
    - **SSH server:** JA
    - **Standard system utilities:** JA
    - **Desktop environment:** NEI (vi trenger ikke GUI)
12. GRUB bootloader: JA, installer pa hoveddisken

## 5. Forste innlogging

Nar maskinen starter opp igjen:

```bash
# Logg inn som eric
# Sjekk IP-adressen:
ip addr show

# Noter IP-adressen (f.eks. 192.168.1.100)
```

## 6. Fast IP (anbefalt)

Rediger nettverksinnstillinger:

```bash
sudo nano /etc/network/interfaces
```

Endre DHCP-linjen til:

```
auto enp0s31f6
iface enp0s31f6 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 1.1.1.1
```

**NB:** Grensesnittnavn (`enp0s31f6`) varierer — sjekk med `ip addr show`.

Restart nettverk:

```bash
sudo systemctl restart networking
```

## 7. Test SSH fra din maskin

Fra din Mac:

```bash
ssh eric@192.168.1.100
```

Fungerer det? Da er du klar for `scripts/01-base-setup.sh`.

## 8. (Valgfritt) SSH-nokkel

For passordlos innlogging:

```bash
# Pa din Mac:
ssh-copy-id eric@192.168.1.100
```

## Tips

- Koble til med nettverkskabel under installasjon (Wi-Fi-drivere kan mangle)
- Skriv ned IP-adressen og passordene
- Nar alt fungerer: lukk lokket og la maskinen sta
