# Invoicer
A dead-simple, easy-to-use minimalist billing application.

<p align="center"><img src="screenshots/sample-invoice.png"></p>

## Downloads
You can <b>download</b> the latest release for <b>Windows</b> [HERE](https://github.com/DexterLagan/invoicer/releases/).

## Features
- produces an invoice in **one click**;
- documents **automatically titled** with invoice number, date and client name;
- **totals** calculation;
- sales **tax**;
- pay **interval**;
- automatic billing and **due dates**;
- localization;
- **simultaneous** export to **HTML**, **PDF** and **printer**;
- **invoice number tracking** accross an unlimited number of **recurring clients**.
- **tiny** (12 MB compressed);
- **portable**;
- **cross-platform** (Windows 32 and 64 bits, Linux and MacOSX);
- adheres to the moto 'the best interface is no interface';
- **free** and open source.

## Planned
- more payment methods;
- invoice line composer?

## Setup
1) create a folder named after your **client**;
2) create or copy the following **settings files** inside the client folder:
- `payee.txt`          - containing the company address;
- `payor.txt`          - containing the client's address;
- `invoice-number.txt` - containing the last current invoice number. Incremented automatically;
- `tax-rate.txt`       - containing the tax name and rate (i.e. HST|13);
- `pay-interval.txt`   - containing the pay interval (i.e. 30);
- `locale.txt`         - containing the date locale (i.e. 'en');
- `branch-address.txt` - containing the bank branch address;
- `account-info.txt`   - containing the bank account information;
- `invoice-lines.txt`  - containing the invoice lines: a brief description followed by the price, separated by a '|';
- `payment-method.txt` - containing the payment method and check number separated by a '|' (if applicable).
3) add a **logo**.

Here is a sample tax rate file:<br>
`HST|13`

Here is a sample invoice line:<br>
`brake bleed|100.00`

Here are examples of payment method file content:<br>
`check|123`<br>
or<br>
`transfert|0`<br>

The check number is ignored when 'transfert' is selected.

## Usage
Two ways, same result:
1) **Double-click on Invoicer**. Browse for the client folder. Out comes a **new invoice**.
2) **Run Invoicer** followed by the folder name **on the command line**. Out comes a **new invoice**.

## What's next
- currencies. Next version will support specifying one currency per client;
- global totals and sales tax for filing.

## Acknowledgements

Invoiced is bundled with a [simple html invoice template](https://github.com/sparksuite/simple-html-invoice-template). Use it, or use your own.
