# South Park: The Stick of Truth - Azerbaijani source

An unofficial fan translation project. It is not affiliated with South Park, Ubisoft, or the game developers.

## Contents

- `translations/az.json` - Azerbaijani strings keyed by game string-table path and ID. It does not include the extracted English dialogue.
- `tools/build_oaf.py` - source builder. It uses the original archive and matching extracted text tables supplied by the user, then creates a translated archive locally.
- `tools/Choose-Language.cmd` and `tools/Switch-Language.ps1` - language menu source.

This source package contains no game archives, executable, extracted English text, or font binaries. The ready-to-install mod on Nexus contains additional binary game resources; this source package does not.

## Build the translated text archive

Install Python 3.10 or newer. Extract the English OAF and its STD resources from your own installed copy, preserving paths such as `global/strings/...std`. Then run:

    python tools/build_oaf.py --oaf "C:/path/to/data_localized_en.oaf" --extracted "C:/path/to/extracted/english" --output "C:/path/to/data_localized_az.oaf"

The tool writes the result on your computer and leaves the supplied game files untouched.

## Rights and distribution

This is a fan translation derived from a copyrighted game. A public source repository does not grant permission to redistribute Ubisoft or South Park material and does not guarantee that public distribution of a translation is permitted. Nexus Mods' [File Submission Guidelines](https://help.nexusmods.com/article/28-file-submission-guidelines) prohibit copyrighted game files without permission and say translations should be submitted as additions that work with the original file. Ask Nexus Mods or the rights holder if you need a definitive answer before public distribution. Do not add game archives, extracted English dialogue, executables, or game fonts here.

The code license covers only the original project tools. Translation entries and third-party material are excluded from that license.

## Azərbaycanca

Bu, South Park: The Stick of Truth üçün qeyri-rəsmi fan tərcüməsidir; South Park, Ubisoft və ya oyunun yaradıcıları ilə əlaqəsi yoxdur.

`translations/az.json` oyun mətnlərinin Azərbaycan dilində qarşılığını fayl yolu və mətn ID-si ilə saxlayır. Arxivdə oyunun orijinal faylları, çıxarılmış ingilis dialoqları, EXE və şriftlər yoxdur. `tools/build_oaf.py` öz oyun nüsxəndən çıxardığın uyğun fayllarla tərcümə arxivi yaradır.

Python 3.10+ quraşdır, orijinal OAF və STD fayllarını öz oyunundan çıxart və yuxarıdakı əmri işə sal. Nəticə sənin kompüterində yaradılır.

Bu tərcümə müəllif hüquqları ilə qorunan oyundan törəyir. GitHub-da mənbə kodunun olması oyunun materiallarını yaymağa icazə vermir və ictimai paylaşımın mütləq icazəli olmasına zəmanət vermir. Nexus Mods qaydalarını və oyunun şərtlərini yoxla; oyun arxivlərini, ingilis dialoqlarını, EXE və şriftləri GitHub-a yükləmə.
