import { initialMarketPlace } from "./test-cases/initial-marketplace";

contract("TerraduxMarketPlace", (accounts) => {
  describe("Initial marketplace", async () => initialMarketPlace());
});
