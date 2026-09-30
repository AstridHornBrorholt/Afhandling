#import "../Config/Macros.typ" : *
#[
  #set heading(numbering: none, outlined: false)
  = Resumé
]

Avanceret styring ved hjælp af digitale systemer kan effektivisere mange former for fysiske processer, så som selvkørende biler, afløbs- og slusesystemer, industriel hydraulik, og el-netværk.
Sikkerheden i sådanne cyber-fysiske systemer er ofte afgørende, da fejl kan føre til alvorlige skader på materiel eller endda mennesker.
Det er derfor vigtigt at korrektheden af de politikker, som de digitale systemer følger, kan verificeres.
Dog er de mest avancerede politikker i dag -- som har den bedste ydeevne -- ofte komplekse.
De repræsenteres af f.eks. neurale netværk, hvis korrekthed er vanskelig at verificere.
Især forstærkningslæring har vist sig som en effektiv metode til at finde frem til poltikker med meget høj ydeevne, når direkte søgning efter en optimal strategi ville være beregningsmæssigt uoverskuelig.

Her er skjolde en lovende metode til sikre korrekt opførsel, uden at verificere politikkernes (eller forstærkningslæringsagneternes) sikkerhed direkte.
Skjolde begrænser den mulige adfærd til en mængde af sikre handlinger for den givne tilstand.
På den måde virker skjoldet som en sikkerhedsbarriere der forhindrer farlige situationer i at opstå.
De syntetiseres ofte ud fra en abstrakt repræsentation af systemet, hvis opførsel kun dækker de dele som er relevante for systemets egentlige sikkerhed.
Ved hjælp af disse abstraktioner er det muligt at opnå sikker opførsel, selvom hele systemet er for komplekst til at finde frem til sikker og optimal opførsel direkte.

Meget forskning har allerede været sat ind på at syntetisere skjolde i flere forskellige sammenhænge, men deres brugbarhed inden for cyber-fysiske systemer har indtil nu været begrænset.
Det skyldes disse systemers unikke udfordringer, så som hybrid opførsel (som blander diskrete skift med kontinuær adfærd), ukendte aspekter af systemet, og flere agenter som interagerer med hinanden på kryds og tværs.

Denne afhandling bidrager til at løse disse udfordringer. 
Der præsenteres en metode til at syntetisere skjolde for hybride systemer på en skalerbar måde.
Denne metodes gøres tilgængelig via en udvidelse til modelleringsredskabet #uppaal.
Ydermere præsenteres en skalerbar metode for multi-agent systemer, via syntese af (simple) lokale skjolde ud fra (komplekse) globale sikkerhedskrav.
Der gives også en metode til at lære et ukendt systems opførsel, mens et adaptivt skjold sørger for sikker opførsel ud fra de eksisterende erfaringer.

Disse metoder kan kombineres for at levere verificerbart sikker opførsel i cyber-fysiske systemer.
Under et skjold kan forstærkningslæring bruges til at opnå en sikker og optimeret politik.