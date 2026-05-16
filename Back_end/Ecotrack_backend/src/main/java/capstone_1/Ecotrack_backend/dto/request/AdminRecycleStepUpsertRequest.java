package capstone_1.Ecotrack_backend.dto.request;

public class AdminRecycleStepUpsertRequest {
    private String stepTitle;
    private String stepDescription;
    private String instructionImageUrl;
    private String instructionVideoUrl;

    public String getStepTitle() {
        return stepTitle;
    }

    public void setStepTitle(String stepTitle) {
        this.stepTitle = stepTitle;
    }

    public String getStepDescription() {
        return stepDescription;
    }

    public void setStepDescription(String stepDescription) {
        this.stepDescription = stepDescription;
    }

    public String getInstructionImageUrl() {
        return instructionImageUrl;
    }

    public void setInstructionImageUrl(String instructionImageUrl) {
        this.instructionImageUrl = instructionImageUrl;
    }

    public String getInstructionVideoUrl() {
        return instructionVideoUrl;
    }

    public void setInstructionVideoUrl(String instructionVideoUrl) {
        this.instructionVideoUrl = instructionVideoUrl;
    }
}
