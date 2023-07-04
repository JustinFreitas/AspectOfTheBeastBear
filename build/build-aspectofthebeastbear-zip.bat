:: Assumes running from AspectOfTheBeastBear\build
mkdir out\AspectOfTheBeastBear
copy ..\extension.xml out\AspectOfTheBeastBear\
copy ..\readme.txt out\AspectOfTheBeastBear\
mkdir out\AspectOfTheBeastBear\graphics\icons
copy ..\graphics\icons\bear_icon.png out\AspectOfTheBeastBear\graphics\icons\
mkdir out\AspectOfTheBeastBear\scripts
copy ..\scripts\aspect_of_the_beast_bear.lua out\AspectOfTheBeastBear\scripts\
cd out
CALL ..\zip-items AspectOfTheBeastBear
rmdir /S /Q AspectOfTheBeastBear\
copy AspectOfTheBeastBear.zip AspectOfTheBeastBear.ext
cd ..
explorer .\out
