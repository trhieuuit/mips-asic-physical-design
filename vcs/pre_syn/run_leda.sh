#!/bin/bash

echo "================================================="
echo " RUNNING LEDA LINTING CHECK (BATCH MODE)"
echo "================================================="
rm -rf leda.log leda_work/ leda_report.txt

leda +v2k ../../rtl/*.v -top mips_cpu_top > leda_report.txt

echo "=> Leda check complete!"
echo "=> Open 'leda_report.txt' to view warnings and errors."

head -n 20 leda_report.txt
