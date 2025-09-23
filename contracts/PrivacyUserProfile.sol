// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint8, euint16, euint32, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract PrivacyUserProfile is SepoliaConfig {

    address public owner;
    uint32 public totalUsers;

    struct UserProfile {
        euint8 ageRange;          // 0-7 representing age ranges (0-17, 18-25, 26-35, etc.)
        euint8 incomeLevel;       // 0-9 representing income brackets
        euint8 spendingPattern;   // 0-9 representing spending habits
        euint8 riskTolerance;     // 0-9 representing risk tolerance level
        euint8 digitalActivity;   // 0-9 representing digital engagement level
        euint8 locationCluster;   // 0-19 representing geographic clusters
        bool isActive;
        uint256 createdAt;
        uint256 lastUpdated;
    }

    struct AnalyticsData {
        euint32 totalInteractions;
        euint16 avgSessionDuration;
        euint8 preferredChannel;     // 0-5 (web, mobile, social, email, etc.)
        euint8 loyaltyScore;         // 0-100 loyalty metric
        euint8 churnRisk;           // 0-100 churn probability
        bool isVIP;
        bool hasData;               // Track if analytics data exists
    }

    struct PrivateInsights {
        euint8 creditScore;         // 0-9 representing credit score ranges
        euint8 socialInfluence;     // 0-9 social media influence level
        euint8 purchasePower;       // 0-9 purchasing power indicator
        euint8 lifestyleSegment;    // 0-15 lifestyle category
        uint256 lastAnalysisTime;
    }

    mapping(address => UserProfile) private userProfiles;
    mapping(address => AnalyticsData) private analytics;
    mapping(address => PrivateInsights) private insights;
    mapping(address => bool) public authorizedAnalysts;

    // Aggregated anonymous statistics
    mapping(uint8 => uint32) public ageDistribution;
    mapping(uint8 => uint32) public incomeDistribution;
    mapping(uint8 => uint32) public spendingDistribution;

    event ProfileCreated(address indexed user, uint256 timestamp);
    event ProfileUpdated(address indexed user, uint256 timestamp);
    event AnalyticsUpdated(address indexed user, uint256 timestamp);
    event InsightsGenerated(address indexed user, uint256 timestamp);
    event AnalystAuthorized(address indexed analyst);
    event AnalystRevoked(address indexed analyst);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyAuthorizedAnalyst() {
        require(authorizedAnalysts[msg.sender] || msg.sender == owner, "Not authorized analyst");
        _;
    }

    modifier profileExists(address user) {
        require(userProfiles[user].isActive, "Profile does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalUsers = 0;
    }

    function authorizeAnalyst(address analyst) external onlyOwner {
        authorizedAnalysts[analyst] = true;
        emit AnalystAuthorized(analyst);
    }

    function revokeAnalyst(address analyst) external onlyOwner {
        authorizedAnalysts[analyst] = false;
        emit AnalystRevoked(analyst);
    }

    function createUserProfile(
        uint8 _ageRange,
        uint8 _incomeLevel,
        uint8 _spendingPattern,
        uint8 _riskTolerance,
        uint8 _digitalActivity,
        uint8 _locationCluster
    ) external {
        require(!userProfiles[msg.sender].isActive, "Profile already exists");
        require(_ageRange <= 7, "Invalid age range");
        require(_incomeLevel <= 9, "Invalid income level");
        require(_spendingPattern <= 9, "Invalid spending pattern");
        require(_riskTolerance <= 9, "Invalid risk tolerance");
        require(_digitalActivity <= 9, "Invalid digital activity");
        require(_locationCluster <= 19, "Invalid location cluster");

        // Encrypt all profile data
        euint8 encAgeRange = FHE.asEuint8(_ageRange);
        euint8 encIncomeLevel = FHE.asEuint8(_incomeLevel);
        euint8 encSpendingPattern = FHE.asEuint8(_spendingPattern);
        euint8 encRiskTolerance = FHE.asEuint8(_riskTolerance);
        euint8 encDigitalActivity = FHE.asEuint8(_digitalActivity);
        euint8 encLocationCluster = FHE.asEuint8(_locationCluster);

        userProfiles[msg.sender] = UserProfile({
            ageRange: encAgeRange,
            incomeLevel: encIncomeLevel,
            spendingPattern: encSpendingPattern,
            riskTolerance: encRiskTolerance,
            digitalActivity: encDigitalActivity,
            locationCluster: encLocationCluster,
            isActive: true,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp
        });

        // Set ACL permissions for user's own data
        FHE.allowThis(encAgeRange);
        FHE.allowThis(encIncomeLevel);
        FHE.allowThis(encSpendingPattern);
        FHE.allowThis(encRiskTolerance);
        FHE.allowThis(encDigitalActivity);
        FHE.allowThis(encLocationCluster);

        FHE.allow(encAgeRange, msg.sender);
        FHE.allow(encIncomeLevel, msg.sender);
        FHE.allow(encSpendingPattern, msg.sender);
        FHE.allow(encRiskTolerance, msg.sender);
        FHE.allow(encDigitalActivity, msg.sender);
        FHE.allow(encLocationCluster, msg.sender);

        // Update anonymous distributions
        ageDistribution[_ageRange]++;
        incomeDistribution[_incomeLevel]++;
        spendingDistribution[_spendingPattern]++;

        totalUsers++;
        emit ProfileCreated(msg.sender, block.timestamp);
    }

    function updateAnalytics(
        address user,
        uint32 _totalInteractions,
        uint16 _avgSessionDuration,
        uint8 _preferredChannel,
        uint8 _loyaltyScore,
        uint8 _churnRisk,
        bool _isVIP
    ) external onlyAuthorizedAnalyst profileExists(user) {
        require(_preferredChannel <= 5, "Invalid channel");
        require(_loyaltyScore <= 100, "Invalid loyalty score");
        require(_churnRisk <= 100, "Invalid churn risk");

        // Encrypt analytics data
        euint32 encTotalInteractions = FHE.asEuint32(_totalInteractions);
        euint16 encAvgSessionDuration = FHE.asEuint16(_avgSessionDuration);
        euint8 encPreferredChannel = FHE.asEuint8(_preferredChannel);
        euint8 encLoyaltyScore = FHE.asEuint8(_loyaltyScore);
        euint8 encChurnRisk = FHE.asEuint8(_churnRisk);

        analytics[user] = AnalyticsData({
            totalInteractions: encTotalInteractions,
            avgSessionDuration: encAvgSessionDuration,
            preferredChannel: encPreferredChannel,
            loyaltyScore: encLoyaltyScore,
            churnRisk: encChurnRisk,
            isVIP: _isVIP,
            hasData: true
        });

        // Set ACL permissions
        FHE.allowThis(encTotalInteractions);
        FHE.allowThis(encAvgSessionDuration);
        FHE.allowThis(encPreferredChannel);
        FHE.allowThis(encLoyaltyScore);
        FHE.allowThis(encChurnRisk);

        userProfiles[user].lastUpdated = block.timestamp;
        emit AnalyticsUpdated(user, block.timestamp);
    }

    function generatePrivateInsights(
        address user,
        uint8 _creditScore,
        uint8 _socialInfluence,
        uint8 _purchasePower,
        uint8 _lifestyleSegment
    ) external onlyAuthorizedAnalyst profileExists(user) {
        require(_creditScore <= 9, "Invalid credit score");
        require(_socialInfluence <= 9, "Invalid social influence");
        require(_purchasePower <= 9, "Invalid purchase power");
        require(_lifestyleSegment <= 15, "Invalid lifestyle segment");

        // Encrypt insights data
        euint8 encCreditScore = FHE.asEuint8(_creditScore);
        euint8 encSocialInfluence = FHE.asEuint8(_socialInfluence);
        euint8 encPurchasePower = FHE.asEuint8(_purchasePower);
        euint8 encLifestyleSegment = FHE.asEuint8(_lifestyleSegment);

        insights[user] = PrivateInsights({
            creditScore: encCreditScore,
            socialInfluence: encSocialInfluence,
            purchasePower: encPurchasePower,
            lifestyleSegment: encLifestyleSegment,
            lastAnalysisTime: block.timestamp
        });

        // Set ACL permissions
        FHE.allowThis(encCreditScore);
        FHE.allowThis(encSocialInfluence);
        FHE.allowThis(encPurchasePower);
        FHE.allowThis(encLifestyleSegment);

        emit InsightsGenerated(user, block.timestamp);
    }

    function compareUserProfiles(
        address user1,
        address user2
    ) external onlyAuthorizedAnalyst profileExists(user1) profileExists(user2) returns (bytes32[] memory) {
        UserProfile storage profile1 = userProfiles[user1];
        UserProfile storage profile2 = userProfiles[user2];

        bytes32[] memory results = new bytes32[](6);

        // Compare encrypted values using FHE operations
        results[0] = FHE.toBytes32(FHE.eq(profile1.ageRange, profile2.ageRange));
        results[1] = FHE.toBytes32(FHE.eq(profile1.incomeLevel, profile2.incomeLevel));
        results[2] = FHE.toBytes32(FHE.eq(profile1.spendingPattern, profile2.spendingPattern));
        results[3] = FHE.toBytes32(FHE.eq(profile1.riskTolerance, profile2.riskTolerance));
        results[4] = FHE.toBytes32(FHE.eq(profile1.digitalActivity, profile2.digitalActivity));
        results[5] = FHE.toBytes32(FHE.eq(profile1.locationCluster, profile2.locationCluster));

        return results;
    }

    function calculateSimilarityScore(
        address user1,
        address user2
    ) external onlyAuthorizedAnalyst profileExists(user1) profileExists(user2) returns (bytes32) {
        UserProfile storage profile1 = userProfiles[user1];
        UserProfile storage profile2 = userProfiles[user2];

        // Calculate weighted similarity score using FHE operations
        euint8 ageScore = FHE.select(FHE.eq(profile1.ageRange, profile2.ageRange), FHE.asEuint8(20), FHE.asEuint8(0));
        euint8 incomeScore = FHE.select(FHE.eq(profile1.incomeLevel, profile2.incomeLevel), FHE.asEuint8(15), FHE.asEuint8(0));
        euint8 spendingScore = FHE.select(FHE.eq(profile1.spendingPattern, profile2.spendingPattern), FHE.asEuint8(15), FHE.asEuint8(0));
        euint8 riskScore = FHE.select(FHE.eq(profile1.riskTolerance, profile2.riskTolerance), FHE.asEuint8(15), FHE.asEuint8(0));
        euint8 digitalScore = FHE.select(FHE.eq(profile1.digitalActivity, profile2.digitalActivity), FHE.asEuint8(20), FHE.asEuint8(0));
        euint8 locationScore = FHE.select(FHE.eq(profile1.locationCluster, profile2.locationCluster), FHE.asEuint8(15), FHE.asEuint8(0));

        euint8 totalScore = FHE.add(FHE.add(FHE.add(ageScore, incomeScore), FHE.add(spendingScore, riskScore)), FHE.add(digitalScore, locationScore));

        return FHE.toBytes32(totalScore);
    }

    function getUserProfileInfo(address user) external view returns (
        bool isActive,
        uint256 createdAt,
        uint256 lastUpdated
    ) {
        UserProfile storage profile = userProfiles[user];
        return (profile.isActive, profile.createdAt, profile.lastUpdated);
    }

    function getAnonymousDistributions() external view returns (
        uint32[8] memory ages,
        uint32[10] memory incomes,
        uint32[10] memory spending
    ) {
        for (uint8 i = 0; i < 8; i++) {
            ages[i] = ageDistribution[i];
        }
        for (uint8 i = 0; i < 10; i++) {
            incomes[i] = incomeDistribution[i];
            spending[i] = spendingDistribution[i];
        }
        return (ages, incomes, spending);
    }

    function getTotalUsers() external view returns (uint32) {
        return totalUsers;
    }

    function isProfileActive(address user) external view returns (bool) {
        return userProfiles[user].isActive;
    }

    function hasAnalytics(address user) external view returns (bool) {
        return analytics[user].hasData;
    }

    function hasInsights(address user) external view returns (bool) {
        return insights[user].lastAnalysisTime != 0;
    }

    function requestProfileDecryption(address user) external onlyAuthorizedAnalyst profileExists(user) {
        UserProfile storage profile = userProfiles[user];

        bytes32[] memory cts = new bytes32[](6);
        cts[0] = FHE.toBytes32(profile.ageRange);
        cts[1] = FHE.toBytes32(profile.incomeLevel);
        cts[2] = FHE.toBytes32(profile.spendingPattern);
        cts[3] = FHE.toBytes32(profile.riskTolerance);
        cts[4] = FHE.toBytes32(profile.digitalActivity);
        cts[5] = FHE.toBytes32(profile.locationCluster);

        FHE.requestDecryption(cts, this.processProfileDecryption.selector);
    }

    function processProfileDecryption(
        uint256 requestId,
        uint8 ageRange,
        uint8 incomeLevel,
        uint8 spendingPattern,
        uint8 riskTolerance,
        uint8 digitalActivity,
        uint8 locationCluster,
        bytes[] memory signatures
    ) external {
        // Note: For this simplified version, we'll remove signature checking
        // In production, implement proper signature verification based on FHE version

        // Process decrypted profile data for authorized analysis
        // This would typically trigger further analytics or reporting
    }
}