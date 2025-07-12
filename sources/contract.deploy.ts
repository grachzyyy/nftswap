import * as fs from "fs";
import * as path from "path";
import { Address, contractAddress } from "@ton/core";
import { Task5 } from "./output/sample_Task5";
import { prepareTactDeployment } from "@tact-lang/deployer";

(async (): Promise<void> => {
    // Parameters
    let testnet = true;
    let packageName = "sample_Task5.pkg";
    let owner = Address.parse("0QClacqt1G1VQ9sasHogYbaMn0pZJdTKnrZBfYmDXOELmu4E");
    let init = await Task5.init(0n, owner);

    // Load required data
    let address = contractAddress(0, init);
    let data = init.data.toBoc();
    let pkg = fs.readFileSync(path.resolve(__dirname, "output", packageName));

    // Prepareing
    console.log("Uploading package...");
    let prepare = await prepareTactDeployment({ pkg, data, testnet });

    // Deploying
    console.log("============================================================================================");
    console.log("Contract Address");
    console.log("============================================================================================");
    console.log();
    console.log(address.toString({ testOnly: testnet }));
    console.log();
    console.log("============================================================================================");
    console.log("Please, follow deployment link");
    console.log("============================================================================================");
    console.log();
    console.log(prepare);
    console.log();
    console.log("============================================================================================");
})();
