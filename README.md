# Invoicer
A dead-simple, easy-to-use minimalist billing application.

<p align="center"><img src="screenshots/sample-invoice.png"></p>

# Downloads
You can <b>download</b> the latest release for <b>Windows x64</b> [HERE](https://github.com/DexterLagan/invoicer/releases/).

# Features
- produces an invoice in **one click**;
- documents **automatically titled** with invoice number, date and client name;
- **totals** calculation;
- sales **tax**;
- pay **interval**;
- automatic billing and **due dates**;
- localization;
- **simultaneous** export to **HTML**, **PDF** and **printer**;
- **invoice number tracking** accross an unlimited number of **recurring clients**.
- **tiny** (14 MB compressed);
- **portable**;
- **cross-platform** (Windows 32 and 64 bits, Linux and MacOSX);
- adheres to the moto 'the best interface is no interface';
- **free** and open source.

## Setup
1) create a folder named after your **client**;
2) create, copy or edit the following **settings files**:
- payee.txt          - containing the company address;
- payor.txt          - containing the client's address;
- invoice-number.txt - containing the last current invoice number. Incremented automatically;
- tax-rate.txt       - containing the tax rate (i.e. 13);
- pay-interval.txt   - containing the pay interval (i.e. 30);
- locale.txt         - containing the date locale (i.e. 'en');
- branch-address.txt - containing the bank branch address;
- account-info.txt   - containing the bank account information;
- invoice-lines.txt  - containing the invoice lines: a brief description followed by the price, separated by a '|';
- payment-method.txt - containing the payment method and check number separated by a '|' (if applicable).
4) add a **logo**.

## Usage
Two ways, same result:
1) **Double-click on Invoicer**. Browse for the client folder. Out comes a **new invoice**.
2) **Run Invoicer** followed by the folder name **on the command line**. Out comes a **new invoice**.

## What's next
- currencies. Next version will support specifying one currency per client;
- global totals and sales tax for filing.

## Acknowledgements

Invoiced is bundled with a [simple html invoice template](https://github.com/sparksuite/simple-html-invoice-template). Use it, or use your own.
