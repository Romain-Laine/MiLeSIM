function cr = nn2an(r, c)
% convert number, number format to alpha, number format
%t = [floor(c/27) + 64 floor((c - 1)/26) - 2 + rem(c - 1, 26) + 65];

Method = 2;

if Method == 1 % only works up to 702 columns (AA --> ZZ)
t = [floor((c - 1)/26) + 64 rem(c - 1, 26) + 65];
if(t(1)<65), t(1) = []; end
cr = [char(t) num2str(r)];

elseif Method == 2 % works for the whole sheet
    Out = ExcelCol(c);
    cr = [Out{1} num2str(r)];
end



end


