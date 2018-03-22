exports.config = 
  rabbitMq:
    connect: process.env.RABBITMQ_BIGWIG_URL || 'amqp://L6Pr-jcX:DE4CaVsraUHVzH1pdFGWiO7o0ns8WcU_@black-vilthuril-36.bigwig.lshift.net:10000/tGtdT4ExyWi4'
    ingestorQ: process.env.INGESTOR_Q || 'ingestor'
    errorQ: process.env.ERROR_Q || process.env.INGESTOR_Q || 'ingestor'
  aws:
    shiftBucket: process.env.SHIFT_INGESTOR_BUCKET || 'xsiteingestor'
    access_key_id: process.env.AWSAccessKeyId || "AKIAIYMT6B27XYCQDQ3Q"
    secret_access_key: process.env.AWSSecretKey || "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"
  parallel:
    uploadFiles: process.env.MAX_SFTP_UPLOAD_FILES || 5
    uploadSites: process.env.MAX_SFTP_UPLOAD_SITES || 5
    uploadAtTimes: process.env.MAX_AT_TIMES_PER_SITE || null
