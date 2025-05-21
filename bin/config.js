module.exports = {
    groupId: "",
    destination: "./output/",
    poolInterval: 250,
    minPoolInterval: 100,
    maxPoolInterval: 500,
    throttle: 0,
    maxFileSize: 1024 * 1024 * 1024, // 1 GB
    retryStatusCodes: [408, 413, 429, 500, 502, 503, 504, 521, 522, 524],
    retryDelay: 1000,
    retryLimit: 5,
    fhirClient: {
        clientId: "@CLIENT_ID@",
        baseUrl: "@FHIR_URL@",
        tokenEndpoint: "@TOKEN_URL@",
        privateJWKorSecret: @JWK@
    },
    resources: {
        //AllergyIntolerance: `?patient=#{patientId}`,
        //Condition         : `?patient=#{patientId}`,
        //Device            : `?patient=#{patientId}`,
        //DiagnosticReport  : `?patient=#{patientId}`,
        //DocumentReference : `?patient=#{patientId}`,
        //Encounter         : `?patient=#{patientId}`,
        //Immunization      : `?patient=#{patientId}`,
        //MedicationRequest : `?patient=#{patientId}`,
        //Observation       : `?patient=#{patientId}&_include=Observation:hasMember:Observation&@OBSERVATION_QUERY@`,
        //Procedure         : `?patient=#{patientId}`,
        //ServiceRequest    : `?patient=#{patientId}`,
        //Patient           : `?identifier=@MRN_SYSTEM@#{patientId}`
    }
};
