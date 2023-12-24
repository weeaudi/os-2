#include "disk.h"
#include "x86.h"

bool DISK_Initialize(DISK *disk, uint8_t driveNumber)
{

    uint8_t driveType;
    uint16_t cylinders, sectors, heads;

    if (!x86_Disk_GetDriveParams(driveNumber, &driveType, &cylinders, &sectors, &heads))
        return false;

    disk->id = driveNumber;
    disk->cylinders = cylinders + 1;
    disk->sectors = sectors;
    disk->heads = heads + 1;

    return true;
}

void DISK_LBA2CHS(DISK *disk, uint32_t lba, uint16_t *cylindersOut, uint16_t *headsOut, uint16_t *sectorsOut)
{
    // sector = (lba % sectors per track + 1)
    *sectorsOut = lba % disk->sectors + 1;

    // cylinder = (lba / sectors per track) / heads
    *cylindersOut = (lba / disk->sectors) / disk->heads;

    // head = (bla / sectors per track) % heads
    *headsOut = (lba / disk->sectors) % disk->heads;
}

bool DISK_ReadSectors(DISK *disk, uint32_t lba, uint8_t sectors, void far *dataOut)
{
    uint16_t cylinder, head, sector;

    DISK_LBA2CHS(disk, lba, &cylinder, &head, &sector);

    for (int i = 0; i < 3; i++)
    {
        if (x86_Disk_Read(disk->id, cylinder, head, sector, sectors, dataOut))
            return true;

        x86_Disk_Reset(disk->id);
    }

    return false;
}
