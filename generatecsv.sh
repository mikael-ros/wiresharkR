for i in *.pcapng;
do tshark -r $i -o 'gui.column.format: "Absolute Time", %Yt, "Bytes", "%L"' > $i.csv;
done;
