function [h] = callaspen(pfad,Visible)
h = actxserver('Apwn.Document');
invoke(h,'InitFromArchive2', pfad);
set(h, 'Visible', Visible); % bei 1 öffne Aspen und zeigt Flowsheet, bei 0 im Hintergrund und man sieht Apen nicht
end