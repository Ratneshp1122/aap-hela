// scripts/deploy.js — Deploy all AAP contracts to HeLa
const hre = require("hardhat");
const fs  = require("fs");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("\n🚀 Deploying Agent Audit Protocol to", hre.network.name);
  console.log("   Deployer:", deployer.address);
  console.log("   Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "HELA\n");

  // ── 1. AgentRegistry ────────────────────────────────────────────────────
  console.log("📋 Deploying AgentRegistry...");
  const AgentRegistry = await hre.ethers.getContractFactory("AgentRegistry");
  const agentRegistry = await AgentRegistry.deploy();
  await agentRegistry.waitForDeployment();
  const agentRegistryAddr = await agentRegistry.getAddress();
  console.log("   ✓ AgentRegistry:", agentRegistryAddr);

  // ── 2. PolicyRegistry ───────────────────────────────────────────────────
  console.log("📋 Deploying PolicyRegistry...");
  const PolicyRegistry = await hre.ethers.getContractFactory("PolicyRegistry");
  const policyRegistry = await PolicyRegistry.deploy();
  await policyRegistry.waitForDeployment();
  const policyRegistryAddr = await policyRegistry.getAddress();
  console.log("   ✓ PolicyRegistry:", policyRegistryAddr);

  // ── 3. ChallengeRegistry ────────────────────────────────────────────────
  console.log("📋 Deploying ChallengeRegistry...");
  const ChallengeRegistry = await hre.ethers.getContractFactory("ChallengeRegistry");
  const challengeRegistry = await ChallengeRegistry.deploy(agentRegistryAddr);
  await challengeRegistry.waitForDeployment();
  const challengeRegistryAddr = await challengeRegistry.getAddress();
  console.log("   ✓ ChallengeRegistry:", challengeRegistryAddr);

  // ── 4. AuditAnchor ──────────────────────────────────────────────────────
  console.log("📋 Deploying AuditAnchor...");
  const AuditAnchor = await hre.ethers.getContractFactory("AuditAnchor");
  const auditAnchor = await AuditAnchor.deploy();
  await auditAnchor.waitForDeployment();
  const auditAnchorAddr = await auditAnchor.getAddress();
  console.log("   ✓ AuditAnchor:", auditAnchorAddr);

  // ── Save addresses ───────────────────────────────────────────────────────
  const addresses = {
    network:          hre.network.name,
    chainId:          (await hre.ethers.provider.getNetwork()).chainId.toString(),
    deployer:         deployer.address,
    deployedAt:       new Date().toISOString(),
    AgentRegistry:    agentRegistryAddr,
    PolicyRegistry:   policyRegistryAddr,
    ChallengeRegistry:challengeRegistryAddr,
    AuditAnchor:      auditAnchorAddr,
  };

  fs.writeFileSync(
    "./deployed_addresses.json",
    JSON.stringify(addresses, null, 2)
  );

  console.log("\n✅ All contracts deployed!");
  console.log("   Addresses saved to deployed_addresses.json");
  console.log("\n📊 Summary:");
  console.log(JSON.stringify(addresses, null, 2));

  console.log("\n🔗 View on HeLa Explorer:");
  const explorerBase = hre.network.name === "hela_mainnet"
    ? "https://helascan.io/address/"
    : "https://testnet-helascan.io/address/";
  Object.entries(addresses).forEach(([k, v]) => {
    if (v.startsWith("0x")) console.log(`   ${k}: ${explorerBase}${v}`);
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
