import { parse } from "csv-parse/sync";

export async function downloadAndParseCSV(url) {
    try {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const csvText = await response.text();

        // Basic validation that we got CSV data
        if (csvText.includes("<!DOCTYPE html>")) {
            throw new Error(
                "Received HTML instead of CSV data. Please check the URL format.",
            );
        }

        return parse(csvText, {
            columns: true,
            skip_empty_lines: true,
            trim: true,
        });
    } catch (error) {
        console.error("Error downloading CSV:", error.message);
        if (error.message.includes("HTML")) {
            console.error(
                "\nThe URL might be incorrect. For Google Sheets, make sure to use the export URL format:",
            );
            console.error(
                "https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/export?format=csv&gid={SHEET_ID}",
            );
        }
        throw error;
    }
}

export function buildCSVRepresentation(records) {
    const filteredRecords = records.filter(
        (record) => record.Status === "ACTIVE",
    );
    const groups = filteredRecords.reduce((groups, record) => {
        const chain = record.Chain;
        if (!groups[chain]) {
            groups[chain] = [];
        }
        const isFactory = record.isFactory === "TRUE";
        groups[chain].push({
            accountAddress: record.Address,
            childContractScope: isFactory ? 3 : 0,
            isFactory: isFactory,
        });
        return groups;
    }, {});

    return groups;
}
