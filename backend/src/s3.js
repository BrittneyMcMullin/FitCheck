const { S3Client, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { Upload } = require('@aws-sdk/lib-storage');
require('dotenv').config();

const s3 = new S3Client({
    region: process.env.AWS_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    }
});

const uploadToS3 = async (file) => {
    const key = `items/${Date.now()}-${file.originalname}`;
    
    const upload = new Upload({
        client: s3,
        params: {
            Bucket: process.env.AWS_BUCKET_NAME,
            Key: key,
            Body: file.buffer,
            ContentType: file.mimetype,
        }
    });

    const result = await upload.done();
    return result.Location;
};

const deleteFromS3 = async (imageUrl) => {
    if (!imageUrl) return;
    const key = imageUrl.split('.amazonaws.com/')[1];
    await s3.send(new DeleteObjectCommand({
        Bucket: process.env.AWS_BUCKET_NAME,
        Key: key,
    }));
};

module.exports = { uploadToS3, deleteFromS3 };